#!/bin/bash
# À charger dans le shell courant avec : source maintenance/check_disk.sh
# Fournit des fonctions pour consulter les erreurs noyau liées à sda et lire ou
# modifier sa profondeur de file d'attente (modification non persistante).

# Affiche les messages noyau du jour contenant le disque indiqué, timeout ou error.
# Paramètres : [disque] — valeur par défaut : sda.
check_disk_error(){
    local disk="${1:-sda}"

    sudo journalctl -k --since "today" | grep -Ei "${disk}|timeout|error"
}

# Affiche la profondeur actuelle de la file d'attente du disque indiqué.
# Paramètres : [disque] — valeur par défaut : sda.
check_disk_queue_depth(){
    local disk="${1:-sda}"
    local queue_depth
    queue_depth=$(cat "/sys/block/${disk}/device/queue_depth") || return
    echo "Queue depth for ${disk}: ${queue_depth}"
}

# Modifie la profondeur de file d'attente jusqu'au prochain redémarrage.
# Paramètres : profondeur (obligatoire), [disque] — valeur par défaut : sda.
set_disk_queue_depth(){
    local queue_depth="${1:-}"
    local disk="${2:-sda}"

    if [ -z "$queue_depth" ]; then
        echo "Usage: set_disk_queue_depth <profondeur> [disque]" >&2
        return 2
    fi

    echo "$queue_depth" > "/sys/block/${disk}/device/queue_depth"
}

# Affiche l'aide des fonctions de vérification du disque.
# Paramètres : aucun.
check_disk_help(){
    cat <<'HELP'
Fonctions disponibles (charger avec : source maintenance/check_disk.sh)

  check_disk_help
      Affiche cette aide. Aucun paramètre.

  check_disk_error [disque]
      Affiche les messages noyau depuis aujourd'hui contenant le disque,
      "timeout" ou "error". Le disque vaut "sda" par défaut.
      Exemple : check_disk_error sdb

  check_disk_queue_depth [disque]
      Affiche la profondeur de file d'attente du disque. Le disque vaut
      "sda" par défaut.
      Exemple : check_disk_queue_depth sdb

  set_disk_queue_depth <profondeur> [disque]
      Définit la profondeur de file d'attente. La profondeur est obligatoire ;
      le disque vaut "sda" par défaut. Nécessite les droits root et la valeur
      ne persiste pas après un redémarrage.
      Exemple : set_disk_queue_depth 32 sdb
HELP
}