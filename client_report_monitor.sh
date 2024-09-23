#!/bin/bash
# Script pour envoyer les informations du client au broker MQTT

BROKER_IP="PPP"
MQTT_USER="USPAS"
MQTT_PASS="PASW"
TOPIC="/client/monitoring"

# Récupérer l'IP locale
    IP_CLIENT=$(hostname -I | awk '{print $1}')

# URLs à récupérer
URLS=(
    "http://$IP_CLIENT:1985/api/v1/vhosts/"
    "http://$IP_CLIENT:1985/api/v1/client/"
    "http://$IP_CLIENT:1985/api/v1/streams/"
    "http://$IP_CLIENT:1985/api/v1/publish/"
    "http://$IP_CLIENT:1985/api/v1/play/"
)

while true; do    

    # Initialisation d'une liste JSON vide
    JSON_LIST="["

    # Boucler sur les URLs et récupérer les JSONs
    for url in "${URLS[@]}"; do
        # Télécharger le JSON
        json_data=$(curl -s $url)

        # Remplacer la valeur de "server" par $IP_CLIENT
        json_modified=$(echo $json_data | sed "s/\"server\": *\"[^\"]*\"/\"server\": \"$IP_CLIENT\"/g")

        # Ajouter le JSON modifié à la liste JSON
        JSON_LIST="$JSON_LIST$json_modified,"
    done

    # Retirer la dernière virgule et fermer la liste JSON
    JSON_LIST=$(echo $JSON_LIST | sed 's/,$//')
    JSON_LIST="$JSON_LIST]"

    # Publier les informations sur le topic MQTT
    mosquitto_pub -h "$BROKER_IP" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$TOPIC" -m "$JSON_LIST"

    # Afficher un message de succès
    if [ $? -eq 0 ]; then
        echo "Informations envoyées avec succès au broker MQTT."
    else
        echo "Erreur lors de l'envoi des informations au broker MQTT."
    fi

    # Attendre 4 secondes avant de répéter
    sleep 4
done