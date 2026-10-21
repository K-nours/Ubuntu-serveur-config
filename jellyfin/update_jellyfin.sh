#!/usr/bin/env bash

set -Eeuo pipefail

trap 'printf "Erreur à la ligne %s : mise à jour interrompue.\n" "$LINENO" >&2' ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  printf "Erreur : Docker n'est pas installé ou n'est pas disponible dans le PATH.\n" >&2
  exit 1
fi

if [[ ! -f docker-compose.yml ]]; then
  printf "Erreur : docker-compose.yml est introuvable dans %s.\n" "$SCRIPT_DIR" >&2
  exit 1
fi

docker compose version >/dev/null

OLD_CONTAINER_ID="$(docker container ls --all --quiet --filter 'name=^/jellyfin$')"
OLD_IMAGE_ID=""
if [[ -n "$OLD_CONTAINER_ID" ]]; then
  OLD_IMAGE_ID="$(docker container inspect --format '{{.Image}}' "$OLD_CONTAINER_ID")"
fi

printf "Téléchargement de la dernière image Jellyfin...\n"
docker compose pull jellyfin

printf "Redémarrage de Jellyfin avec la nouvelle image...\n"
docker compose up -d jellyfin

if [[ -n "$OLD_IMAGE_ID" ]]; then
  NEW_IMAGE_ID="$(docker container inspect --format '{{.Image}}' jellyfin)"
  if [[ "$OLD_IMAGE_ID" != "$NEW_IMAGE_ID" ]]; then
    DANGLING_IMAGE_IDS="$(docker image ls --quiet --no-trunc --filter dangling=true)"
    if printf '%s\n' "$DANGLING_IMAGE_IDS" | grep --fixed-strings --line-regexp --quiet -- "$OLD_IMAGE_ID"; then
      OTHER_CONTAINER_IDS="$(docker container ls --all --quiet --filter "ancestor=$OLD_IMAGE_ID")"
      if [[ -z "$OTHER_CONTAINER_IDS" ]]; then
        printf "Suppression de l'ancienne image Jellyfin %s...\n" "$OLD_IMAGE_ID"
        docker image rm "$OLD_IMAGE_ID"
      else
        printf "Ancienne image Jellyfin conservée : elle est encore utilisée par un autre conteneur.\n"
      fi
    else
      printf "Ancienne image conservée : elle est encore référencée par un tag ou n'est plus disponible.\n"
    fi
  fi
fi

printf "Mise à jour de Jellyfin terminée.\n"