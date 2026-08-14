# TODO
# Create folder structure in /srv/nass/dockers/jellyfin
# Run docker-compose up -d
# NEXT
# configure DuckDNS to point to the server
# configure Nginx to reverse proxy to Jellyfin

sudo mkdir -p /srv/nass/dockers/jellyfin
sudo mkdir -p /srv/nass/dockers/jellyfin/config
sudo mkdir -p /srv/nass/dockers/jellyfin/cache

docker compose up -d