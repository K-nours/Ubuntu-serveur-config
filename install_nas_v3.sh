#!/bin/bash
set -e

user_name=""
nas_group="nasusers"
local_storage_path=""

network_name=$(hostname)

while [[ $# -gt 0 ]]; do
        case "$1" in
            --user-name) user_name="$2"; shift 2 ;;
            --nas-group) nas_group="$2"; shift 2 ;;
            --local-storage-path) local_storage_path="$2"; shift 2 ;;
            --network-name) network_name="$2"; shift 2 ;;            
            *) echo "Option inconnue : $1" >&2; exit 1 ;;
        esac
    done

if [[ -z "$user_name" || -z "$nas_group" || -z "$local_storage_path" ]]; then
    echo "Usage: $0 --user-name <username> --nas-group <groupname> --local-storage-path <path> --samba-password <password>" >&2
    exit 1
fi

if [[ ! -d "$local_storage_path" ]]; then
    echo "Erreur : le dossier ${local_storage_path} n'existe pas." >&2
    exit 1
fi


echo "=== Création du groupe ${nas_group} ==="
if ! getent group "${nas_group}" >/dev/null; then
    sudo groupadd "${nas_group}"
fi

echo "=== Ajout de ${user_name} dans le groupe ${nas_group} ==="
sudo usermod -aG "${nas_group}" "${user_name}"

echo "=== Création de la structure NAS ==="

sudo mkdir -p "${local_storage_path}/media"
sudo mkdir -p "${local_storage_path}/documents"
sudo mkdir -p "${local_storage_path}/backups"
sudo mkdir -p "${local_storage_path}/docker"

sudo mkdir -p /srv/nas/media
sudo mkdir -p /srv/nas/documents
sudo mkdir -p /srv/nas/backups
sudo mkdir -p /srv/nas/docker

echo "=== Permissions Unix ==="
sudo chown -R ${user_name}:"${nas_group}" "${local_storage_path}"
sudo chmod -R 775 "${local_storage_path}"

sudo chown -R ${user_name}:"${nas_group}" /srv/nas
sudo chmod -R 775 /srv/nas

echo "=== Configuration des bind mounts ==="

if ! grep -q "${local_storage_path}/media" /etc/fstab; then
sudo bash -c "cat >> /etc/fstab <<EOF
${local_storage_path}/media     /srv/nas/media     none    bind    0 0
${local_storage_path}/documents /srv/nas/documents none    bind    0 0
${local_storage_path}/backups   /srv/nas/backups   none    bind    0 0
${local_storage_path}/docker    /srv/nas/docker    none    bind    0 0
EOF"
fi

sudo mount -a

echo "=== Installation de Samba ==="
sudo apt install -y samba || { echo "Erreur installation Samba"; exit 1; }


echo "=== Configuration Samba ==="
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak 2>/dev/null || true
sudo bash -c "cat > /etc/samba/smb.conf << EOF
[global]
   workgroup = WORKGROUP
   server string = ${network_name} NAS
   security = user
   map to guest = never
   unix extensions = no

   # Découverte réseau Windows
   netbios name = ${network_name}
   local master = yes
   preferred master = yes
   os level = 255

[nas-media]
   path = /srv/nas/media
   browseable = yes
   writable = yes
   valid users = "${user_name}"
   force user = "${user_name}"
   force group = "${nas_group}"
   create mask = 0775
   directory mask = 0775

[nas-documents]
   path = /srv/nas/documents
   browseable = yes
   writable = yes
   valid users = "${user_name}"
   force user = "${user_name}"
   force group = "${nas_group}"
   create mask = 0775
   directory mask = 0775

[nas-backups]
   path = /srv/nas/backups
   browseable = yes
   writable = yes
   valid users = "${user_name}"
   force user = "${user_name}"
   force group = "${nas_group}"
   create mask = 0775
   directory mask = 0775

[nas-docker]
   path = /srv/nas/docker
   browseable = yes
   writable = yes
   valid users = "${user_name}"
   force user = "${user_name}"
   force group = "${nas_group}"
   create mask = 0775
   directory mask = 0775
EOF"

echo "=== Création de l’utilisateur Samba ==="
sudo smbpasswd -a "${user_name}"


echo "=== Redémarrage Samba ==="
sudo systemctl restart smbd

echo "=== Installation du serveur NFS ==="
sudo apt install -y nfs-kernel-server

echo "=== Configuration NFS ==="
sudo cp /etc/exports /etc/exports.bak 2>/dev/null || true

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

echo "=== NAS Samba + NFS installé avec succès ==="
echo "Partages disponibles : /srv/nas/*"
echo "Stockage réel : ${local_storage_path}/*"