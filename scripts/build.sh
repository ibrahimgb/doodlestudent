#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${CI_REGISTRY:-}" || -z "${CI_REGISTRY_IMAGE:-}" || -z "${CI_REGISTRY_USER:-}" || -z "${CI_REGISTRY_PASSWORD:-}" ]]; then
  echo "Missing GitLab registry variables. Ensure CI_REGISTRY, CI_REGISTRY_IMAGE, CI_REGISTRY_USER, CI_REGISTRY_PASSWORD are set." >&2
  exit 1
fi

TAG="${CI_COMMIT_SHA:-local}"
REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"

API_IMAGE="$REGISTRY_IMAGE/api:$TAG"
NGINX_IMAGE="$REGISTRY_IMAGE/nginx:$TAG"

printf '%s' "$CI_REGISTRY_PASSWORD" | docker login "$CI_REGISTRY" -u "$CI_REGISTRY_USER" --password-stdin

docker build -f Dockerfile.api -t "$API_IMAGE" .
docker build -f Dockerfile.frontend -t "$NGINX_IMAGE" .

docker push "$API_IMAGE"
docker push "$NGINX_IMAGE"

if [[ "${CI_COMMIT_BRANCH:-}" == "master" ]]; then
  docker tag "$API_IMAGE" "$REGISTRY_IMAGE/api:latest"
  docker tag "$NGINX_IMAGE" "$REGISTRY_IMAGE/nginx:latest"
  docker push "$REGISTRY_IMAGE/api:latest"
  docker push "$REGISTRY_IMAGE/nginx:latest"
fi
