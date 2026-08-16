#!/bin/bash
#
# Copier les script dans /usr/local/bin/duckdns.sh
# mettre lescript en executale : chmod +x /usr/local/bin/duckdns.sh
# editer cron : crontab -e
# ajouter la ligne suivante pour mettre à jour l'IP toutes les 5 minutes :
# */5 * * * * /usr/local/bin/duckdns.sh >/dev/null 2>&1


# Domaine DuckDNS
DOMAIN="k-nours"
TOKEN="TON_TOKEN_ICI"

# Appel DuckDNS
curl -s "https://www.duckdns.org/update?domains=${DOMAIN}&token=${TOKEN}&ip=" > /var/log/duckdns.log
