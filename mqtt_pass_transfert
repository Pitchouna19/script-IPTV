#!/bin/bash
# Script pour envoyer les informations du fichier JSON au broker MQTT si le contenu change

BROKER_IP="PPP"
MQTT_USER="USPAS"
MQTT_PASS="PASW"
TOPIC="/client/pass"
FILE_PATH="/etc/openresty/pass.json"

# Initialiser le dernier hash à une valeur vide
LAST_HASH=""

while true; do
    # Calculer le hash actuel du fichier
    CURRENT_HASH=$(md5sum "$FILE_PATH" | awk '{print $1}')
    
    # Vérifier si le hash a changé
    if [ "$CURRENT_HASH" != "$LAST_HASH" ]; then
        # Mettre à jour LAST_HASH avec le nouveau hash
        LAST_HASH="$CURRENT_HASH"
        
        # Lire et compacter le contenu du fichier JSON en une seule ligne
        MESSAGE=$(jq -c . "$FILE_PATH")
        
        # Publier les informations sur le topic MQTT
        mosquitto_pub -h "$BROKER_IP" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$TOPIC" -m "$MESSAGE"
        
        echo "Changement détecté, message envoyé : $MESSAGE"
    fi
    
    # Attendre 4 secondes avant de vérifier à nouveau
    sleep 4
done
