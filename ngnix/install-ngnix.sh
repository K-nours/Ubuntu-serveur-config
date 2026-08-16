sudo mkdir -p /srv/npm/data
sudo mkdir -p /srv/npm/letsencrypt
sudo docker compose up -d

echo "Nginx Proxy Manager installed successfully!"
echo "Access it at http://<your-server-ip>:81"