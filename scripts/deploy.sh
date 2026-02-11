#!/usr/bin/env bash
# ============================================================================
# deploy.sh
# Déploie l'application Doodle sur une VM distante via SSH.
#
# Fichiers transférés :
#   - docker-compose.prod.yml
#   - .env
#   - nginx/nginx-ssl.conf.template
#   - scripts/init-letsencrypt.sh
#   - scripts/setup-firewall.sh
#
# Variables CI/CD requises :
#   DEPLOY_HOST, DEPLOY_USER, DEPLOY_PATH
#   CI_REGISTRY, CI_REGISTRY_IMAGE, CI_REGISTRY_USER, CI_REGISTRY_PASSWORD
#   SSH_PRIVATE_KEY (optionnel — clé privée SSH)
# ============================================================================
set -euo pipefail

: "${DEPLOY_HOST:?Missing DEPLOY_HOST}"
: "${DEPLOY_USER:?Missing DEPLOY_USER}"
: "${DEPLOY_PATH:?Missing DEPLOY_PATH}"
: "${CI_REGISTRY:?Missing CI_REGISTRY}"
: "${CI_REGISTRY_IMAGE:?Missing CI_REGISTRY_IMAGE}"
: "${CI_REGISTRY_USER:?Missing CI_REGISTRY_USER}"
: "${CI_REGISTRY_PASSWORD:?Missing CI_REGISTRY_PASSWORD}"

DEPLOY_TAG="${DEPLOY_TAG:-${CI_COMMIT_SHA:-latest}}"
API_IMAGE="$CI_REGISTRY_IMAGE/api:$DEPLOY_TAG"
NGINX_IMAGE="$CI_REGISTRY_IMAGE/nginx:$DEPLOY_TAG"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Configuration SSH ---
SSH_KEY_FILE=""
if [[ -n "${SSH_PRIVATE_KEY:-}" ]]; then
  SSH_KEY_FILE="/tmp/deploy_key"
  printf '%s' "$SSH_PRIVATE_KEY" > "$SSH_KEY_FILE"
  chmod 600 "$SSH_KEY_FILE"
fi

SSH_OPTS=("-o" "StrictHostKeyChecking=no")
if [[ -n "$SSH_KEY_FILE" ]]; then
  SSH_OPTS+=("-i" "$SSH_KEY_FILE")
fi

# --- Créer les répertoires distants ---
echo ">>> Création des répertoires sur la VM..."
ssh "${SSH_OPTS[@]}" "$DEPLOY_USER@$DEPLOY_HOST" \
  "mkdir -p $DEPLOY_PATH/nginx $DEPLOY_PATH/scripts"

# --- Copier tous les fichiers nécessaires ---
echo ">>> Transfert des fichiers de déploiement..."
scp "${SSH_OPTS[@]}" \
  "$PROJECT_ROOT/docker-compose.prod.yml" \
  "$PROJECT_ROOT/.env" \
  "$DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH/"

scp "${SSH_OPTS[@]}" \
  "$PROJECT_ROOT/nginx/nginx-ssl.conf.template" \
  "$DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH/nginx/"

scp "${SSH_OPTS[@]}" \
  "$PROJECT_ROOT/scripts/init-letsencrypt.sh" \
  "$PROJECT_ROOT/scripts/setup-firewall.sh" \
  "$DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH/scripts/"

# --- Pull des images et démarrage ---
echo ">>> Déploiement sur $DEPLOY_HOST..."
ssh "${SSH_OPTS[@]}" "$DEPLOY_USER@$DEPLOY_HOST" \
  "cd $DEPLOY_PATH && \
  chmod +x scripts/*.sh && \
  printf '%s' '$CI_REGISTRY_PASSWORD' | docker login '$CI_REGISTRY' -u '$CI_REGISTRY_USER' --password-stdin && \
  DOODLE_API_IMAGE='$API_IMAGE' DOODLE_NGINX_IMAGE='$NGINX_IMAGE' \
  docker compose -f docker-compose.prod.yml pull && \
  DOODLE_API_IMAGE='$API_IMAGE' DOODLE_NGINX_IMAGE='$NGINX_IMAGE' \
  docker compose -f docker-compose.prod.yml up -d --remove-orphans"

echo ""
echo "========================================"
echo " ✅ Déploiement terminé sur $DEPLOY_HOST"
echo "========================================"
echo ""
echo "Si c'est le premier déploiement, exécutez sur la VM :"
echo "  1. sudo $DEPLOY_PATH/scripts/setup-firewall.sh"
echo "  2. sudo $DEPLOY_PATH/scripts/init-letsencrypt.sh"

# --- Nettoyage ---
if [[ -n "$SSH_KEY_FILE" ]]; then
  rm -f "$SSH_KEY_FILE"
fi
