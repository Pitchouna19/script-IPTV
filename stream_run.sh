#!/bin/bash

# Définir le chemin du fichier JSON source et de sortie
JSON_FILE="/var/www/html/monitoring.json"
OUTPUT_FILE="/var/www/html/streaming_run.json"
TEMP_FILE="/var/www/html/streaming_run_temp.json"

while true; do
  # Vérifier si le fichier monitoring.json existe
  if [[ ! -f "$JSON_FILE" ]]; then
    echo "Erreur : Le fichier $JSON_FILE est introuvable."
    exit 1
  fi

  # Vérifier si le fichier temporaire existe, sinon le créer
  if [[ ! -f "$TEMP_FILE" ]]; then
    touch "$TEMP_FILE"
  fi

  # Générer le contenu du fichier streaming_run.json dans un fichier temporaire
  echo "[" > "$TEMP_FILE"  # Début du tableau JSON

  # Lire chaque serveur et récupérer les informations nécessaires
  jq -c '.[]' "$JSON_FILE" | while read -r server_info; do
    # Extraire l'IP du serveur
    server=$(echo "$server_info" | jq -r '.server')

    # Extraire et nettoyer les noms des streams actifs
    streams=$(echo "$server_info" | jq -c '[.streams[] | select(.publish.active == true)]')

    # Concaténer les noms sans extension
    channels=$(echo "$streams" | jq -r '[.[].name | sub("\\.(flv|mp4|m3u8|ts|avi|mov)$"; "")] | join("|")')

    # Extraire les valeurs des champs "clients" et "streams" depuis "vhosts"
    clients_total=$(echo "$server_info" | jq '[.vhosts[].clients] | add')
    streams_total=$(echo "$server_info" | jq '[.vhosts[].streams] | add')

    # Calculer nbc = clients_total - streams_total
    nbc=$((clients_total - streams_total))

    # Calculer nbcompe : soustraire 1 de chaque valeur de "clients" et les concaténer
    nbcompe=$(echo "$streams" | jq -r '[.[] | .clients - 1] | join("|")')

    # Si aucun stream actif n'est trouvé, passer au serveur suivant
    if [[ -z "$channels" ]]; then
      continue
    fi

    # Construire le tableau des channels avec .clients - 1
    channel_array=$(echo "$streams" | jq -c '[.[] | {nom: .name, id: .id, clients: (.clients - 1), cid: .publish.cid}]')

    # Construire le tableau des clients avec .publish == false et enlever les extensions des noms
    client_array=$(echo "$server_info" | jq -c '[.clients[] | select(.publish == false) | {nom: (.name | sub("\\.(flv|mp4|m3u8|ts|avi|mov)$"; "")), id: .id, ip: .ip, alive: .alive}]')

    # Écrire l'objet JSON pour ce serveur dans le fichier temporaire
    echo "{" >> "$TEMP_FILE"
    echo "  \"serveur\": \"$server\"," >> "$TEMP_FILE"
    echo "  \"channel\": $channel_array," >> "$TEMP_FILE"
    echo "  \"client\": $client_array," >> "$TEMP_FILE"
    echo "  \"nbcompe\": \"$nbcompe\"," >> "$TEMP_FILE"
    echo "  \"nbc\": $nbc," >> "$TEMP_FILE"
    echo "  \"nbs\": $streams_total" >> "$TEMP_FILE"
    echo "}," >> "$TEMP_FILE"
  done

  # Supprimer la dernière virgule et fermer le tableau JSON
  sed -i '$ s/,$//' "$TEMP_FILE"
  echo "]" >> "$TEMP_FILE"

  # Remplacer le fichier de sortie final par le fichier temporaire
  mv "$TEMP_FILE" "$OUTPUT_FILE"

  echo "Le fichier $OUTPUT_FILE a été généré avec succès."

  # Attendre 3 secondes avant la prochaine exécution
  sleep 3
done
