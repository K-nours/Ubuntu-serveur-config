#!/bin/bash
set -e

echo "=== Création du groupe nasusers si absent ==="
if ! getent group nasusers >/dev/null; then
    sudo groupadd nasusers
fi

echo "=== Ajout de gbadmin dans le groupe nasusers ==="
sudo usermod -aG nasusers gbadmin

echo "=== Correction des permissions Unix sur /mnt/storage ==="
sudo chown -R gbadmin:nasusers /mnt/storage
sudo chmod -R 775 /mnt/storage

echo "=== Correction des permissions Unix sur /srv/nas ==="
sudo chown -R gbadmin:nasusers /srv/nas
sudo chmod -R 775 /srv/nas

echo "=== Mise à jour de la configuration Samba ==="
sudo bash -c 'cat > /etc/samba/smb.conf << "EOF"
[global]
   workgroup = WORKGROUP
   server string = Tatooine NAS
   security = user
   map to guest = never
   unix extensions = no

[nas-media]
   path = /srv/nas/media
   browseable = yes
   writable = yes
   valid users = gbadmin
   force user = gbadmin
   force group = nasusers
   create mask = 0775
   directory mask = 0775

[nas-documents]
   path = /srv/nas/documents
   browseable = yes
   writable = yes
   valid users = gbadmin
   force user = gbadmin
   force group = nasusers
   create mask = 0775
   directory mask = 0775

[nas-backups]
   path = /srv/nas/backups
   browseable = yes
   writable = yes
   valid users = gbadmin
   force user = gbadmin
   force group = nasusers
   create mask = 0775
   directory mask = 0775

[nas-docker]
   path = /srv/nas/docker
   browseable = yes
   writable = yes
   valid users = gbadmin
   force user = gbadmin
   force group = nasusers
   create mask = 0775
   directory mask = 0775
EOF'

echo "=== Redémarrage de Samba ==="
sudo systemctl restart smbd

echo "=== Vérification des permissions ==="
ls -ld /mnt/storage
ls -ld /srv/nas
ls -l /srv/nas

echo "=== Correction terminée ==="
echo "Testez maintenant l’écriture depuis Windows."

