#!/bin/bash

set -e

echo "=== Mise à jour du système ==="
sudo apt update -y
sudo apt upgrade -y

echo "=== Installation de XFCE4 ==="
sudo apt install -y xfce4

echo "=== Installation de XRDP ==="
sudo apt install -y xrdp
sudo systemctl enable --now xrdp

echo "=== Configuration du startwm.sh pour XFCE ==="
sudo bash -c 'cat > /etc/xrdp/startwm.sh << "EOF"
#!/bin/sh
if [ -r /etc/default/locale ]; then
    . /etc/default/locale
    export LANG LANGUAGE
fi
startxfce4
EOF'

sudo chmod +x /etc/xrdp/startwm.sh

echo "=== Configuration de la session utilisateur ==="
echo "xfce4-session" > ~/.xsession

echo "=== Ajout de xrdp au groupe ssl-cert ==="
sudo adduser xrdp ssl-cert

echo "=== Ajout de l'utilisateur courant au groupe ssl-cert ==="
sudo adduser "$USER" ssl-cert

echo "=== Création de la règle polkit moderne ==="
sudo bash -c 'cat > /etc/polkit-1/rules.d/45-allow-xrdp.rules << "EOF"
polkit.addRule(function(action, subject) {
    if (subject.isInGroup("ssl-cert")) {
        return polkit.Result.YES;
    }
});
EOF'

echo "=== Redémarrage des services ==="
sudo systemctl restart polkit
sudo systemctl restart xrdp

echo "=== Installation terminée ==="
echo "Vous pouvez maintenant vous connecter via RDP."

