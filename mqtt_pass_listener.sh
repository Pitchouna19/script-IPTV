#!/bin/bash
# Script pour écouter sur le topic /client/pass et remplacer le contenu de pass.json par chaque message reçu

TOPIC="/client/pass"
JSON_FILE="/etc/openresty/pass.json"
BROKER_IP="PPP"
MQTT_USER="USPAS"
MQTT_PASS="PASW"

# Initialiser le fichier JSON vide s'il n'existe pas
sudo bash -c "echo '[]' > $JSON_FILE"
sudo chmod 666 $JSON_FILE  # S'assurer que le fichier est accessible en écriture

# Fonction pour remplacer le contenu du JSON par le message reçu, uniquement s'il est bien formé
replace_json_content() {
    local message=$1

    # Vérifier si le message est bien un JSON avec la clé "pass"
    if echo "$message" | jq -e 'has("pass")' > /dev/null 2>&1; then
        # Remplacer le contenu du fichier par le message reçu
        echo "$message" | sudo tee "$JSON_FILE" > /dev/null
        echo "Contenu JSON mis à jour : $message"
    else
        echo "Message ignoré, format JSON incorrect : $message"
    fi
}

# Écouter les messages sur le topic et traiter chaque message
mosquitto_sub -h "$BROKER_IP" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$TOPIC" | while read -r message
do
    # Afficher le message reçu pour déboguer
    echo "Message reçu : $message"

    # Remplacer le contenu du fichier JSON par le nouveau message si valide
    replace_json_content "$message"
done
