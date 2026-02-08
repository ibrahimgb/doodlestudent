#!/usr/bin/env bash
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

scp "${SSH_OPTS[@]}" "$PROJECT_ROOT/docker-compose.prod.yml" "$DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH/docker-compose.prod.yml"

ssh "${SSH_OPTS[@]}" "$DEPLOY_USER@$DEPLOY_HOST" \
  "cd $DEPLOY_PATH && \
  printf '%s' '$CI_REGISTRY_PASSWORD' | docker login '$CI_REGISTRY' -u '$CI_REGISTRY_USER' --password-stdin && \
  DOODLE_API_IMAGE='$API_IMAGE' DOODLE_NGINX_IMAGE='$NGINX_IMAGE' \
  docker compose -f docker-compose.prod.yml pull && \
  DOODLE_API_IMAGE='$API_IMAGE' DOODLE_NGINX_IMAGE='$NGINX_IMAGE' \
  docker compose -f docker-compose.prod.yml up -d --remove-orphans"

if [[ -n "$SSH_KEY_FILE" ]]; then
  rm -f "$SSH_KEY_FILE"
fi
