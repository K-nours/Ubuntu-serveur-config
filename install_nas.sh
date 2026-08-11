#!/bin/bash
set -e

echo "=== Création de la structure NAS ==="

sudo mkdir -p /mnt/storage/media
sudo mkdir -p /mnt/storage/documents
sudo mkdir -p /mnt/storage/backups
sudo mkdir -p /mnt/storage/docker

sudo mkdir -p /srv/nas/media
sudo mkdir -p /srv/nas/documents
sudo mkdir -p /srv/nas/backups
sudo mkdir -p /srv/nas/docker

echo "=== Configuration des bind mounts ==="

if ! grep -q "/mnt/storage/media" /etc/fstab; then
sudo bash -c 'cat >> /etc/fstab << "EOF"
/mnt/storage/media     /srv/nas/media     none    bind    0 0
/mnt/storage/documents /srv/nas/documents none    bind    0 0
/mnt/storage/backups   /srv/nas/backups   none    bind    0 0
/mnt/storage/docker    /srv/nas/docker    none    bind    0 0
EOF'
fi

sudo mount -a

echo "=== Installation de Samba ==="
sudo apt install -y samba

echo "=== Configuration Samba ==="

sudo bash -c 'cat > /etc/samba/smb.conf << "EOF"
[global]
   workgroup = WORKGROUP
   server string = Tatooine NAS
   netbios name = TATOOINE
   security = user
   map to guest = never
   unix extensions = no

   # Découverte réseau Windows
   local master = yes
   preferred master = yes
   os level = 255

[nas-media]
   path = /srv/nas/media
   browseable = yes
   writable = yes
   valid users = gbadmin
   create mask = 0660
   directory mask = 0770

[nas-documents]
   path = /srv/nas/documents
   browseable = yes
   writable = yes
   valid users = gbadmin
   create mask = 0660
   directory mask = 0770

[nas-backups]
   path = /srv/nas/backups
   browseable = yes
   writable = yes
   valid users = gbadmin
   create mask = 0660
   directory mask = 0770

[nas-docker]
   path = /srv/nas/docker
   browseable = yes
   writable = yes
   valid users = gbadmin
   create mask = 0660
   directory mask = 0770
EOF'

echo "=== Création de l’utilisateur Samba ==="
sudo smbpasswd -a gbadmin

echo "=== Redémarrage Samba ==="
sudo systemctl restart smbd

echo "=== Installation du serveur NFS ==="
sudo apt install -y nfs-kernel-server

echo "=== Configuration NFS (mode simple root_squash) ==="

sudo bash -c 'cat > /etc/exports << "EOF"
/srv/nas/media     192.168.1.0/24(rw,sync,root_squash)
/srv/nas/documents 192.168.1.0/24(rw,sync,root_squash)
/srv/nas/backups   192.168.1.0/24(rw,sync,root_squash)
/srv/nas/docker    192.168.1.0/24(rw,sync,root_squash)
EOF'

sudo exportfs -ra
sudo systemctl restart nfs-server

echo "=== Installation de WS-Discovery (Windows Network Discovery) ==="
sudo apt remove -y wsdd || true
sudo apt install -y wsdd2
sudo systemctl enable --now wsdd2

echo "=== Installation de mDNS (avahi) ==="
sudo apt install -y avahi-daemon
sudo systemctl enable --now avahi-daemon

echo "=== Ouverture du firewall (si UFW actif) ==="
if sudo ufw status | grep -q "active"; then
    sudo ufw allow Samba
    sudo ufw allow 3702/udp
fi

echo "=== NAS Samba + NFS + Découverte réseau Windows installé avec succès ==="
echo "Partages disponibles : /srv/nas/*"
echo "Stockage réel : /mnt/storage/*"
echo "Découverte réseau Windows activée via wsdd"
