#!/bin/bash

# Chemins des fichiers JSON
KICKOFF_FILE="/var/www/html/kickoff.json"
MONITORING_FILE="/var/www/html/monitoring.json"

# Vérification si jq est installé
if ! command -v jq &> /dev/null; then
  echo "Erreur : 'jq' n'est pas installé. Installe-le avec 'sudo apt install jq'."
  exit 1
fi

# Fonction principale qui lit le fichier kickoff.json et déclenche des actions
scan_kickoff() {
  if [[ ! -f "$KICKOFF_FILE" ]]; then
    echo "Fichier $KICKOFF_FILE introuvable."
    exit 1
  fi

  jq -c '.[]' "$KICKOFF_FILE" | while read -r entry; do
    local ip=$(echo "$entry" | jq -r '.ip')
    local time=$(echo "$entry" | jq -r '.time')

    if [[ "$time" != "None" ]]; then
      scan_client_timeout "$ip" "$time"
    fi
  done
}

# Fonction appelée si une IP est trouvée avec un temps défini
scan_client_timeout() {
  local ip="$1"
  local time="$2"
  echo "Lancement de scan_client_timeout avec IP: $ip et time: $time"
  analyze_monitoring_for_ip "$ip" "$time"
}

# Fonction pour analyser le fichier monitoring.json et filtrer les clients
analyze_monitoring_for_ip() {
  local ip="$1"
  local time="$2"

  if [[ ! -f "$MONITORING_FILE" ]]; then
    echo "Fichier $MONITORING_FILE introuvable."
    exit 1
  fi

  local clients=$(jq --arg ip "$ip" '.[] | select(.server == $ip) | .clients' "$MONITORING_FILE")

  if [[ -n "$clients" && "$clients" != "null" ]]; then
    local filtered_clients=$(echo "$clients" | jq '[.[] | select(.type != "fmle-publish")]')

    if [[ "$filtered_clients" != "[]" ]]; then
      echo "Clients filtrés pour $ip:"
      echo "$filtered_clients" | jq .
      process_kickoff_timeout "$filtered_clients" "$ip" "$time"
    else
      echo "Aucun client valide trouvé pour l'IP $ip."
    fi
  else
    echo "Aucun client trouvé pour l'IP $ip."
  fi
}

# Conversion du format de temps (e.g., "20min", "1h") en secondes
convert_to_seconds() {
  local time_str="$1"
  local unit="${time_str//[0-9]/}"
  local value="${time_str//[!0-9]/}"

  case "$unit" in
    min) echo $((value * 60)) ;;
    h)   echo $((value * 3600)) ;;
    s)   echo "$value" ;;
    *)   echo "0" ;;
  esac
}

# Fonction pour traiter les clients filtrés et vérifier leur temps de vie
process_kickoff_timeout() {
  local clients="$1"
  local ip="$2"
  local time_str="$3"
  local time_in_seconds=$(convert_to_seconds "$time_str")

  echo "Traitement des clients pour l'IP: $ip (time = ${time_in_seconds}s)"
  echo "$clients" | jq .

  echo "$clients" | jq -c '.[]' | while read -r client; do
    local alive=$(echo "$client" | jq -r '.alive')
    local id=$(echo "$client" | jq -r '.id')

    if (( $(echo "$alive > $time_in_seconds" | bc -l) )); then
      echo "Client $id a dépassé le temps autorisé ($alive s > $time_in_seconds s)."
      Kill_final "$ip" "$id"
    fi
  done
}

# Fonction pour envoyer une requête DELETE via curl
Kill_final() {
  local ip="$1"
  local id="$2"
  echo "Envoi de la commande DELETE à http://$ip:1985/api/v1/clients/$id"

  curl -v -X DELETE "http://$ip:1985/api/v1/clients/$id" && echo ""
}

# Boucle infinie avec exécution toutes les 60 secondes
while true; do
  echo "Exécution de scan_kickoff à $(date)"
  scan_kickoff
  sleep 60  # Pause de 60 secondes avant la prochaine itération
done
