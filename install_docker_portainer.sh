#!/bin/bash
set -e

echo "=== Mise à jour du système ==="
sudo apt update -y
sudo apt upgrade -y

echo "=== Installation des dépendances Docker ==="
sudo apt install -y ca-certificates curl gnupg lsb-release

echo "=== Ajout de la clé GPG Docker ==="
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "=== Ajout du dépôt Docker ==="
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "=== Installation de Docker Engine + Compose ==="
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== Ajout de l'utilisateur au groupe docker ==="
sudo usermod -aG docker "$USER"

echo "=== Installation de Portainer ==="

sudo mkdir -p /srv/nas/docker/portainer

sudo docker run -d \
  -p 9000:9000 \
  -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /srv/nas/docker/portainer:/data \
  portainer/portainer-ce:latest

network_name=$(hostname)

echo "=== Installation terminée ==="
echo "Accès Portainer : https://${network_name}:9443"
echo "Ou : http://${network_name}:9000"
echo "Déconnecte-toi / reconnecte-toi pour activer le groupe docker."
