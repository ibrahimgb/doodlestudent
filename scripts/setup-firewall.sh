#!/usr/bin/env bash
# ============================================================================
# setup-firewall.sh
# Configure le pare-feu UFW sur la machine virtuelle de déploiement.
#
# Règles appliquées :
#   - Deny tout le trafic entrant par défaut
#   - Allow tout le trafic sortant par défaut
#   - Allow SSH      (port 22/tcp)
#   - Allow HTTP     (port 80/tcp)  — nécessaire pour le challenge Let's Encrypt
#   - Allow HTTPS    (port 443/tcp) — trafic applicatif principal
#
# Usage :  sudo ./scripts/setup-firewall.sh
# ============================================================================
set -euo pipefail

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
  echo "Erreur : ce script doit être exécuté en tant que root (sudo)." >&2
  exit 1
fi

echo "========================================"
echo " Configuration du pare-feu UFW"
echo "========================================"

# --- Réinitialiser les règles existantes ---
echo ">>> Réinitialisation des règles UFW..."
ufw --force reset

# --- Politiques par défaut ---
echo ">>> Politique par défaut : deny entrant, allow sortant"
ufw default deny incoming
ufw default allow outgoing

# --- Règles d'autorisation ---
echo ">>> Autorisation SSH (port 22/tcp)..."
ufw allow 22/tcp comment 'SSH'

echo ">>> Autorisation HTTP (port 80/tcp)..."
ufw allow 80/tcp comment 'HTTP - Let'\''s Encrypt + redirect HTTPS'

echo ">>> Autorisation HTTPS (port 443/tcp)..."
ufw allow 443/tcp comment 'HTTPS - trafic applicatif'

# --- Activer le pare-feu ---
echo ">>> Activation de UFW..."
ufw --force enable

# --- Afficher le statut ---
echo ""
echo "========================================"
echo " ✅ Pare-feu UFW configuré !"
echo "========================================"
ufw status verbose
