#!/bin/bash
set -e

echo "=== Mise à jour du système ==="
sudo apt update -y
sudo apt upgrade -y

echo "=== Installation de Cockpit ==="
sudo apt install -y cockpit cockpit-storaged cockpit-networkmanager cockpit-packagekit cockpit-system

echo "=== Activation du service Cockpit ==="
# Cockpit utilise cockpit.socket, pas cockpit.service
sudo systemctl enable --now cockpit.socket

echo "=== Ouverture du port 9090 si UFW est actif ==="
if sudo ufw status | grep -q "active"; then
    sudo ufw allow 9090/tcp
fi
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

echo "=== Installation terminée ==="
echo "Accès Cockpit : https://tatooine:9090"
echo "Ou : http://tatooine:9090"
