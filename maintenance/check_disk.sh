#!/bin/bash
# À charger dans le shell courant avec : source maintenance/check_disk.sh
# Fournit des fonctions pour consulter les erreurs noyau liées à sda et lire ou
# modifier sa profondeur de file d'attente (modification non persistante).

# Affiche les messages noyau du jour contenant le disque indiqué, timeout ou error.
# Paramètres : [-disk disque] — valeur par défaut de -disk : sda.
check_disk_error(){
    local disk="sda"

    while (($#)); do
        case "$1" in            
            -disk)
                if [[ -z "${2:-}" ]]; then
                    echo "Usage: check_disk_error [-disk disque]" >&2
                    return 2
                fi
                disk="$2"
                shift 2
                ;;
            *)
                echo "Option inconnue pour check_disk_error : $1" >&2
                echo "Usage: check_disk_error [-disk disque]" >&2
                return 2
                ;;
        esac
    done

    sudo journalctl -k --since "today" | grep -Ei "${disk}|timeout|error"
}

# Affiche la profondeur actuelle de la file d'attente du disque indiqué.
# Paramètres : [-disk disque] — valeur par défaut de -disk : sda.
check_disk_queue_depth(){
    local disk="sda"
    local queue_depth

    while (($#)); do
        case "$1" in
            -disk)
                if [[ -z "${2:-}" ]]; then
                    echo "Usage: check_disk_queue_depth [-disk disque]" >&2
                    return 2
                fi
                disk="$2"
                shift 2
                ;;
            *)
                echo "Option inconnue pour check_disk_queue_depth : $1" >&2
                echo "Usage: check_disk_queue_depth [-disk disque]" >&2
                return 2
                ;;
        esac
    done

    queue_depth=$(cat "/sys/block/${disk}/device/queue_depth") || return
    echo "Queue depth for ${disk}: ${queue_depth}"
}

# Modifie la profondeur de file d'attente jusqu'au prochain redémarrage.
# Paramètres : -depth profondeur (obligatoire), [-disk disque] (par défaut : sda).
set_disk_queue_depth(){
    local queue_depth=""
    local disk="sda"

    while (($#)); do
        case "$1" in
            -depth)
                if [[ -z "${2:-}" ]]; then
                    echo "Usage: set_disk_queue_depth -depth profondeur [-disk disque]" >&2
                    return 2
                fi
                queue_depth="$2"
                shift 2
                ;;
            -disk)
                if [[ -z "${2:-}" ]]; then
                    echo "Usage: set_disk_queue_depth -depth profondeur [-disk disque]" >&2
                    return 2
                fi
                disk="$2"
                shift 2
                ;;
            *)
                echo "Option inconnue pour set_disk_queue_depth : $1" >&2
                echo "Usage: set_disk_queue_depth -depth profondeur [-disk disque]" >&2
                return 2
                ;;
        esac
    done

    if [[ -z "$queue_depth" ]]; then
        echo "Usage: set_disk_queue_depth -depth profondeur [-disk disque]" >&2
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

  check_disk_error [-disk disque]
      Affiche les messages noyau depuis aujourd'hui contenant le disque,
      "timeout" ou "error". Le disque vaut "sda" par défaut.
      Exemple : check_disk_error -disk sdb

  check_disk_queue_depth [-disk disque]
      Affiche la profondeur de file d'attente du disque. -disk vaut "sda"
      par défaut.
      Exemple : check_disk_queue_depth -disk sdb

  set_disk_queue_depth -depth profondeur [-disk disque]
      Définit la profondeur de file d'attente. -depth est obligatoire ;
      -disk vaut "sda" par défaut. Nécessite les droits root et la valeur
      ne persiste pas après un redémarrage.
      Exemple : set_disk_queue_depth -depth 32 -disk sdb
HELP
}
