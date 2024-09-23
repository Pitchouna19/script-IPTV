#!/bin/bash
# Script pour écouter sur le topic /client/monitoring et maintenir un tableau JSON unique basé sur l'IP
TOPIC="/client/monitoring"
JSON_FILE="/var/lib/mosquitto/monitoring.json"
BROKER_IP="PPP"
MQTT_USER="USPAS"
MQTT_PASS="PASW"

# Initialiser le fichier JSON vide s'il n'existe pas ou le vider au démarrage
sudo bash -c "echo '[]' > $JSON_FILE"
sudo chmod 666 $JSON_FILE  # S'assurer que le fichier est accessible en écriture

# Fonction pour mettre à jour ou ajouter un client dans le tableau JSON
update_or_add_client() {
    local message="$1"

    # Extraire le serveur (IP) du message reçu
    server_ip=$(echo "$message" | jq -r '.[0].server')

    # Charger l'actuel contenu JSON du fichier
    current_json=$(cat $JSON_FILE)

    # Vérifier si le serveur IP existe déjà dans le fichier JSON
    if echo "$current_json" | jq -e --arg server_ip "$server_ip" '.[] | select(.server == $server_ip)' > /dev/null; then
        # Si le serveur existe, mettre à jour les informations correspondantes
        updated_json=$(echo "$current_json" | jq --argjson new_data "$message" --arg server_ip "$server_ip" '
            map(if .server == $server_ip then . = ($new_data | .[0]) else . end)
        ')
    else
        # Si le serveur n'existe pas, ajouter les nouvelles données à la liste
        updated_json=$(echo "$current_json" | jq --argjson new_data "$message" '. + $new_data')
    fi

    # Écrire le JSON mis à jour dans le fichier
    echo "$updated_json" | sudo tee $JSON_FILE > /dev/null
}

# Écouter les messages sur le topic et traiter chaque message
mosquitto_sub -h "$BROKER_IP" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$TOPIC" | while read -r message
do
    # Afficher le message reçu pour déboguer
    echo "Message reçu : $message"

    # Mettre à jour ou ajouter le client dans le tableau JSON
    update_or_add_client "$message"
done
