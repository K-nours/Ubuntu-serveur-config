#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "Erreur à la ligne %s : mise à jour interrompue.\n" "$LINENO" >&2' ERR

if ! command -v sudo >/dev/null 2>&1; then
  printf "Erreur : sudo est requis pour mettre à jour Cockpit.\n" >&2
  exit 1
fi

packages=(
  cockpit
  cockpit-storaged
  cockpit-networkmanager
  cockpit-packagekit
  cockpit-system
)
upgradable=()
installed_count=0

printf "Actualisation de la liste des paquets...\n"
sudo apt-get update

for package in "${packages[@]}"; do
  if ! package_status="$(dpkg-query -W -f='${db:Status-Status}\t${Version}' "$package" 2>/dev/null)"; then
    continue
  fi

  read -r status installed_version <<< "$package_status"
  if [[ "$status" != "installed" ]]; then
    continue
  fi
  ((installed_count += 1))

  candidate_version="$(apt-cache policy "$package" | awk '$1 == "Candidate:" { print $2; exit }')"
  if [[ -z "$candidate_version" || "$candidate_version" == "(none)" ]]; then
    printf "Aucune version candidate trouvée pour %s.\n" "$package" >&2
    exit 1
  fi

  if dpkg --compare-versions "$candidate_version" gt "$installed_version"; then
    printf "%s : %s -> %s\n" "$package" "$installed_version" "$candidate_version"
    upgradable+=("$package")
  fi
done

if (( installed_count == 0 )); then
  printf "Erreur : aucun paquet Cockpit pris en charge par ce script n'est installé.\n" >&2
  exit 1
fi

if (( ${#upgradable[@]} == 0 )); then
  printf "Cockpit est déjà à jour.\n"
  exit 0
fi

printf "Mise à niveau des paquets Cockpit disponibles...\n"
sudo apt-get install --only-upgrade -y "${upgradable[@]}"

printf "Mise à jour de Cockpit terminée.\n"
