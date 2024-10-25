#!/bin/bash

# Définir le chemin du fichier JSON source et de sortie
JSON_FILE="/var/www/html/monitoring.json"
OUTPUT_FILE="/var/www/html/streaming_run.json"

while true; do
  # Vérifier si le fichier monitoring.json existe
  if [[ ! -f "$JSON_FILE" ]]; then
    echo "Erreur : Le fichier $JSON_FILE est introuvable."
    exit 1
  fi

  # Générer le contenu du fichier streaming_run.json
  echo "[" > "$OUTPUT_FILE"  # Début du tableau JSON

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

    # Écrire l'objet JSON pour ce serveur dans le fichier de sortie
    echo "{" >> "$OUTPUT_FILE"
    echo "  \"serveur\": \"$server\"," >> "$OUTPUT_FILE"
    echo "  \"channel\": \"$channels\"," >> "$OUTPUT_FILE"
    echo "  \"nbcompe\": \"$nbcompe\"," >> "$OUTPUT_FILE"
    echo "  \"nbc\": $nbc," >> "$OUTPUT_FILE"
    echo "  \"nbs\": $streams_total" >> "$OUTPUT_FILE"
    echo "}," >> "$OUTPUT_FILE"
  done

  # Supprimer la dernière virgule et fermer le tableau JSON
  sed -i '$ s/,$//' "$OUTPUT_FILE"
  echo "]" >> "$OUTPUT_FILE"

  echo "Le fichier $OUTPUT_FILE a été généré avec succès."

  # Attendre 3 secondes avant la prochaine exécution
  sleep 3
done
