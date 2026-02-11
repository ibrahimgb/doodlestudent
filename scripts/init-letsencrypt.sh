#!/usr/bin/env bash
# ============================================================================
# init-letsencrypt.sh
# Initialise les certificats Let's Encrypt pour la première fois.
#
# Étapes :
#   1. Crée un certificat auto-signé temporaire (pour que nginx puisse démarrer)
#   2. Démarre nginx
#   3. Supprime le certificat temporaire
#   4. Demande un vrai certificat à Let's Encrypt via le challenge HTTP-01
#   5. Recharge nginx avec le vrai certificat
#
# Usage :  sudo ./scripts/init-letsencrypt.sh
# ============================================================================
set -euo pipefail

# --- Chargement de la configuration depuis .env ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -f "$PROJECT_ROOT/.env" ]]; then
  # shellcheck disable=SC1091
  source "$PROJECT_ROOT/.env"
fi

DOMAIN="${DOODLE_DOMAIN:?Erreur : DOODLE_DOMAIN n'est pas défini dans .env}"
EMAIL="${LETSENCRYPT_EMAIL:?Erreur : LETSENCRYPT_EMAIL n'est pas défini dans .env}"
STAGING="${LETSENCRYPT_STAGING:-0}"  # Mettre à 1 pour tester sans limite de rate

COMPOSE_FILE="$PROJECT_ROOT/docker-compose.prod.yml"
RSA_KEY_SIZE=4096

echo "========================================"
echo " Init Let's Encrypt pour : $DOMAIN"
echo " Email : $EMAIL"
echo " Staging : $STAGING"
echo "========================================"

# --- 1. Créer les répertoires pour certbot ---
echo ">>> Création des volumes Docker..."
docker compose -f "$COMPOSE_FILE" up -d --no-deps --no-start certbot 2>/dev/null || true

# Obtenir le chemin du volume certbot-certs
CERT_VOLUME=$(docker volume inspect --format '{{ .Mountpoint }}' "$(basename "$PROJECT_ROOT")_certbot-certs" 2>/dev/null || echo "")

# Utiliser un conteneur temporaire pour manipuler les fichiers dans le volume
CERT_PATH="/etc/letsencrypt/live/$DOMAIN"

echo ">>> Vérification des certificats existants..."
if docker run --rm -v "$(basename "$PROJECT_ROOT")_certbot-certs:/etc/letsencrypt" \
   alpine sh -c "test -f $CERT_PATH/fullchain.pem" 2>/dev/null; then
  echo "Des certificats existent déjà pour $DOMAIN."
  read -p "Voulez-vous les remplacer ? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Abandon."
    exit 0
  fi
fi

# --- 2. Créer un certificat auto-signé temporaire ---
echo ">>> Création d'un certificat auto-signé temporaire..."
docker run --rm \
  -v "$(basename "$PROJECT_ROOT")_certbot-certs:/etc/letsencrypt" \
  alpine sh -c "
    mkdir -p $CERT_PATH &&
    apk add --no-cache openssl > /dev/null 2>&1 &&
    openssl req -x509 -nodes -newkey rsa:$RSA_KEY_SIZE \
      -days 1 \
      -keyout '$CERT_PATH/privkey.pem' \
      -out '$CERT_PATH/fullchain.pem' \
      -subj '/CN=$DOMAIN'
  "
echo "   Certificat temporaire créé."

# --- 3. Démarrer nginx (avec le certificat temporaire) ---
echo ">>> Démarrage de nginx..."
docker compose -f "$COMPOSE_FILE" up -d nginx
echo "   Nginx démarré. Attente de 5s..."
sleep 5

# --- 4. Supprimer le certificat temporaire ---
echo ">>> Suppression du certificat temporaire..."
docker run --rm \
  -v "$(basename "$PROJECT_ROOT")_certbot-certs:/etc/letsencrypt" \
  alpine sh -c "rm -rf /etc/letsencrypt/live/$DOMAIN"

# --- 5. Demander le vrai certificat à Let's Encrypt ---
echo ">>> Demande du certificat Let's Encrypt..."

STAGING_ARG=""
if [[ "$STAGING" == "1" ]]; then
  STAGING_ARG="--staging"
  echo "   ⚠  Mode STAGING activé (certificat de test)"
fi

docker compose -f "$COMPOSE_FILE" run --rm certbot \
  certbot certonly \
    --webroot \
    -w /var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d "$DOMAIN" \
    $STAGING_ARG

# --- 6. Recharger nginx avec le vrai certificat ---
echo ">>> Rechargement de nginx..."
docker compose -f "$COMPOSE_FILE" exec nginx nginx -s reload

echo ""
echo "========================================"
echo " ✅ Certificat Let's Encrypt installé !"
echo "    Domaine : https://$DOMAIN"
echo "========================================"
echo ""
echo "Vous pouvez maintenant lancer toute la stack :"
echo "  docker compose -f docker-compose.prod.yml up -d"
