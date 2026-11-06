#!/bin/bash
#
# Cherche si des erreur lié au disque sda ont eu lieu au cours de la journée
sudo journalctl -k --since "today" | grep -Ei "sda|timeout|error"
