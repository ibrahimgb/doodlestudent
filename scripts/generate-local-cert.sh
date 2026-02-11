#!/usr/bin/env bash
# ============================================================================
# generate-local-cert.sh
# Génère un certificat auto-signé pour tester HTTPS en local (localhost).
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DOMAIN="${DOODLE_DOMAIN:-localhost}"
CERT_DIR="$PROJECT_ROOT/certs/live/$DOMAIN"

mkdir -p "$CERT_DIR"

echo ">>> Génération d'un certificat auto-signé pour '$DOMAIN'..."
openssl req -x509 -nodes -newkey rsa:2048 \
  -days 365 \
  -keyout "$CERT_DIR/privkey.pem" \
  -out "$CERT_DIR/fullchain.pem" \
  -subj "/CN=$DOMAIN" \
  2>/dev/null

echo "✅ Certificat créé dans $CERT_DIR"
