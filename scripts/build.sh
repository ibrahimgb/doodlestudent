#!/usr/bin/env bash
# ============================================================================
# build.sh
# Build les images Docker (API + Nginx) et les push sur le GitLab Registry.
#
# Tag stratégie :
#   - Toujours : tag avec le SHA du commit (traçabilité)
#   - Sur branche 'deploy' : tag aussi 'latest' (pour le déploiement prod)
# ============================================================================
set -euo pipefail

if [[ -z "${CI_REGISTRY:-}" || -z "${CI_REGISTRY_IMAGE:-}" || -z "${CI_REGISTRY_USER:-}" || -z "${CI_REGISTRY_PASSWORD:-}" ]]; then
  echo "Missing GitLab registry variables. Ensure CI_REGISTRY, CI_REGISTRY_IMAGE, CI_REGISTRY_USER, CI_REGISTRY_PASSWORD are set." >&2
  exit 1
fi

TAG="${CI_COMMIT_SHA:-local}"
REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"

API_IMAGE="$REGISTRY_IMAGE/api:$TAG"
NGINX_IMAGE="$REGISTRY_IMAGE/nginx:$TAG"

echo ">>> Login au registry $CI_REGISTRY..."
printf '%s' "$CI_REGISTRY_PASSWORD" | docker login "$CI_REGISTRY" -u "$CI_REGISTRY_USER" --password-stdin

echo ">>> Build de l'image API..."
docker build -f Dockerfile.api -t "$API_IMAGE" .

echo ">>> Build de l'image Nginx (front)..."
docker build -f Dockerfile.frontend -t "$NGINX_IMAGE" .

echo ">>> Push des images..."
docker push "$API_IMAGE"
docker push "$NGINX_IMAGE"

# Sur la branche deploy → tag 'latest' pour la production
if [[ "${CI_COMMIT_BRANCH:-}" == "deploy" ]]; then
  echo ">>> Branche 'deploy' détectée → tag 'latest'..."
  docker tag "$API_IMAGE" "$REGISTRY_IMAGE/api:latest"
  docker tag "$NGINX_IMAGE" "$REGISTRY_IMAGE/nginx:latest"
  docker push "$REGISTRY_IMAGE/api:latest"
  docker push "$REGISTRY_IMAGE/nginx:latest"
fi

echo "✅ Images build et push terminés"
echo "   API   : $API_IMAGE"
echo "   Nginx : $NGINX_IMAGE"
