# TODO
# Create folder structure in /srv/nass/dockers/jellyfin
# Run docker-compose up -d
# NEXT
# configure DuckDNS to point to the server
# configure Nginx to reverse proxy to Jellyfin

mkdir -p /srv/nas/docker/jellyfin
mkdir -p /srv/nas/docker/jellyfin/config
mkdir -p /srv/nas/docker/jellyfin/cache

docker compose up -d