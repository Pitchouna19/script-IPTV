#!/bin/bash
# Script pour écouter sur le topic /client/info et maintenir un tableau JSON unique basé sur l'IP
TOPIC="/client/info"
JSON_FILE="/var/lib/mosquitto/clients.json"
BROKER_IP="PPP"
MQTT_USER="USPAS"
MQTT_PASS="PASW"

# Initialiser le fichier JSON vide s'il n'existe pas ou le vider au démarrage
sudo bash -c "echo '[]' > $JSON_FILE"
sudo chmod 666 $JSON_FILE  # S'assurer que le fichier est accessible en écriture

# Fonction pour mettre à jour ou ajouter un client dans le tableau JSON
update_or_add_client() {

    sudo echo "[]" >  "$JSON_FILE"
    local message=$1
    local ip=$(echo "$message" | jq -r '.ip')

    # Charger le fichier JSON actuel
    local current_data=$(cat "$JSON_FILE")

    # Vérifier si l'IP existe déjà dans le tableau
    if echo "$current_data" | jq -e ".[] | select(.ip == \"$ip\")" > /dev/null; then
        # Si l'IP existe, mettre à jour les valeurs correspondantes
        current_data=$(echo "$current_data" | jq "map(if .ip == \"$ip\" then $message else . end)")
    else
        # Si l'IP n'existe pas, ajouter une nouvelle entrée
        current_data=$(echo "$current_data" | jq ". += [$message]")
    fi

    # Sauvegarder le nouveau contenu dans le fichier JSON
    echo "$current_data" > "$JSON_FILE"
}

# Écouter les messages sur le topic et traiter chaque message
mosquitto_sub -h "$BROKER_IP" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$TOPIC" | while read -r message
do
    # Afficher le message reçu pour déboguer
    echo "Message reçu : $message"

    # Mettre à jour ou ajouter le client dans le tableau JSON
    update_or_add_client "$message"
done
