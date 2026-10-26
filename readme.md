# Scripts de configuration d'un serveur Ubuntu

Ce dépôt regroupe des scripts pour installer et mettre à jour des services sur un serveur Ubuntu, ainsi que des fichiers Compose pour Jellyfin et Nginx Proxy Manager.

## Prérequis

- Un serveur Ubuntu installé : [ubuntu.com/download/server](https://ubuntu.com/download/server)
- Un accès avec `sudo` pour les scripts d'installation et de configuration.
- Une connexion Internet.
- Pour les scripts Docker : Docker Engine et le plugin Docker Compose (installés par `install_docker_portainer.sh`).

Les scripts d'installation Cockpit, Docker/Portainer et XRDP mettent également à niveau les paquets du système avec `apt upgrade`.

## Scripts à la racine

| Script | Description | Utilisation |
| --- | --- | --- |
| `install_cockpit.sh` | Met à jour Ubuntu, installe Cockpit et ses modules de stockage, réseau, paquets et système, active `cockpit.socket` et ouvre le port TCP 9090 si UFW est actif. | `sudo ./install_cockpit.sh` |
| `update_cockpit.sh` | Actualise APT et met à niveau uniquement les paquets Cockpit pris en charge par le script qui sont déjà installés. Signale une erreur si aucun de ces paquets n'est installé. | `./update_cockpit.sh` |
| `install_docker_portainer.sh` | Installe Docker Engine et Compose depuis le dépôt officiel Docker, ajoute l'utilisateur courant au groupe `docker` et lance Portainer. | `sudo ./install_docker_portainer.sh` |
| `update_portainer.sh` | Récupère l'image Portainer la plus récente, recrée le conteneur `portainer` et conserve ses données dans `/srv/nas/docker/portainer`. | `./update_portainer.sh` |
| `install_nas_v3.sh` | Configure les répertoires et bind mounts du NAS, les permissions, les partages Samba et NFS, ainsi que la découverte réseau Windows et mDNS. | Voir les paramètres ci-dessous. |
| `install_xrdp_xfce.sh` | Met à jour Ubuntu, installe XFCE et XRDP, configure la session XFCE et active XRDP au démarrage. | `sudo ./install_xrdp_xfce.sh` |
| `copyConfigToSrv.ps1` | Depuis PowerShell sous Windows, crée un répertoire distant et y copie les scripts d'installation Cockpit, Docker/Portainer, NAS et XRDP via SSH/SCP. | `.\copyConfigToSrv.ps1` |
| `duckdns.sh` | Appelle l'API DuckDNS pour actualiser l'adresse IP du domaine configuré et écrit la réponse dans `/var/log/duckdns.log`. | À configurer avant de l'exécuter ; exemple de tâche cron ci-dessous. |

### Configuration du NAS

`install_nas_v3.sh` prend les options suivantes :

```bash
sudo ./install_nas_v3.sh \
  --user-name <utilisateur> \
  --nas-group <groupe> \
  --local-storage-path <chemin-du-stockage> \
  --network-name <nom-du-serveur>
```

- `--user-name` : compte Ubuntu auquel attribuer les accès.
- `--nas-group` : groupe NAS (par défaut `nasusers`).
- `--local-storage-path` : répertoire existant où créer `media`, `documents`, `backups` et `docker`.
- `--network-name` : nom annoncé sur le réseau (par défaut, le nom d'hôte).

Le script crée les points de montage sous `/srv/nas`, configure Samba et NFS pour le réseau `192.168.1.0/24`, et demande le mot de passe Samba pour le compte indiqué. Vérifiez et adaptez les chemins et le sous-réseau aux besoins de votre installation avant de l'exécuter.

### Configuration de DuckDNS

Dans `duckdns.sh`, remplacez `DOMAIN` et `TOKEN` par les valeurs de votre domaine. Ne partagez pas le jeton. Pour une mise à jour toutes les cinq minutes, le script peut être installé dans `/usr/local/bin/duckdns.sh`, rendu exécutable, puis ajouté à la crontab :

```cron
*/5 * * * * /usr/local/bin/duckdns.sh >/dev/null 2>&1
```

## Services Docker

Ces commandes supposent que Docker et le plugin Compose sont installés et que l'utilisateur courant peut utiliser Docker.

### Jellyfin (`jellyfin/`)

- `install_jellyfin.sh` crée `/srv/nas/docker/jellyfin/config` et `cache`, puis démarre le service Compose.
- `docker-compose.yml` définit Jellyfin, les ports TCP 8096 et UDP 7359, la configuration persistante et le montage des médias depuis `/srv/nas/media`.
- `update_jellyfin.sh` télécharge l'image Jellyfin, recrée le service avec Compose et supprime l'ancienne image seulement si elle n'est plus utilisée.

Exécuter depuis le répertoire du service :

```bash
cd jellyfin
./install_jellyfin.sh
./update_jellyfin.sh
```

Avant le démarrage, vérifiez dans `docker-compose.yml` l'utilisateur `1000:1000`, le chemin des médias et le montage facultatif des polices (`/path/to/fonts`).

### Nginx Proxy Manager (`ngnix/`)

- `install-ngnix.sh` crée les répertoires `/srv/npm/data` et `/srv/npm/letsencrypt`, puis démarre le service Compose.
- `docker-compose.yml` définit Nginx Proxy Manager avec les ports 80, 81 et 443.

Exécuter depuis le répertoire du service :

```bash
cd ngnix
./install-ngnix.sh
```

L'interface d'administration est annoncée sur `http://<adresse-du-serveur>:81`.

## Accès aux services

- Cockpit : `https://<nom-du-serveur>:9090`
- Portainer : `https://<nom-du-serveur>:9443` (HTTP également exposé sur le port 9000)
- Jellyfin : `http://<adresse-du-serveur>:8096`
- Nginx Proxy Manager : `http://<adresse-du-serveur>:81`

Après l'ajout de l'utilisateur au groupe `docker`, déconnectez-vous puis reconnectez-vous pour que le changement de groupe soit pris en compte.

## Amélioration envisagée

Envisager Ansible pour maintenir plusieurs serveurs si le parc devait s'agrandir.
