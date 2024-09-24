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

    # Extraire l'adresse IP du message reçu (la clé de l'objet)
    server_ip=$(echo "$message" | jq -r 'keys[0]')  # Utiliser keys[0] pour obtenir la clé de l'objet

    # Charger l'actuel contenu JSON du fichier
    current_json=$(cat $JSON_FILE)

    # Extraire les données du serveur du message
    server_data=$(echo "$message" | jq -r '.[keys[0]]')  # Obtenir les données associées à l'IP

    # Vérifier si le serveur IP existe déjà dans le fichier JSON
    if echo "$current_json" | jq -e --arg server_ip "$server_ip" '.[] | select(.server == $server_ip)' > /dev/null; then
        # Si le serveur existe, mettre à jour les informations correspondantes
        updated_json=$(echo "$current_json" | jq --arg server_ip "$server_ip" --argjson new_data "$server_data" '
            map(if .server == $server_ip then . = { server: $server_ip } + $new_data else . end)
        ')
    else
        # Si le serveur n'existe pas, ajouter les nouvelles données à la liste
        updated_json=$(echo "$current_json" | jq --arg server_ip "$server_ip" --argjson new_data "$server_data" '
            . + [{ server: $server_ip } + $new_data]
        ')
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
