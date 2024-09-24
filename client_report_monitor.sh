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
    "http://$IP_CLIENT:1985/api/v1/clients/"
    "http://$IP_CLIENT:1985/api/v1/streams/"
)

while true; do    
    # Initialisation d'une liste JSON vide
    JSON_LIST="["

    # Boucler sur les URLs et récupérer les JSONs
    for url in "${URLS[@]}"; do
        # Télécharger le JSON
        json_data=$(curl -s "$url")

        # Vérifier si le JSON n'est pas vide
        if [[ -n "$json_data" && "$json_data" != "[]" ]]; then
            # Remplacer la valeur de "server" par $IP_CLIENT
            json_modified=$(echo "$json_data" | sed "s/\"server\": *\"[^\"]*\"/\"server\": \"$IP_CLIENT\"/g")

            # Ajouter le JSON modifié à la liste JSON
            JSON_LIST="$JSON_LIST$json_modified,"
        fi
    done

    # Retirer la dernière virgule si elle existe et fermer la liste JSON
    JSON_LIST=$(echo "$JSON_LIST" | sed 's/,$//')
    JSON_LIST="$JSON_LIST]"

    # Si JSON_LIST est vide (juste "[]"), ne pas envoyer
    if [ "$JSON_LIST" != "[]" ]; then
        # Fusionner les données par serveur à l'aide de jq
        JSON_LIST=$(echo "$JSON_LIST" | jq -c '
            reduce .[] as $entry (
                {};
                .[$entry.server] += {
                    vhosts: ((.[$entry.server].vhosts // []) + ($entry.vhosts // [])) | unique,
                    clients: ((.[$entry.server].clients // []) + ($entry.clients // [])) | unique,
                    streams: ((.[$entry.server].streams // []) + ($entry.streams // [])) | unique
                }
            )
        ')

        # Vérifier si la commande jq a réussi
        if [ $? -ne 0 ]; then
            echo "Erreur lors du traitement JSON avec jq."
            exit 1
        fi

        # Publier les informations sur le topic MQTT
        mosquitto_pub -h "$BROKER_IP" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$TOPIC" -m "$JSON_LIST"

        # Afficher un message de succès
        if [ $? -eq 0 ]; then
            echo "Informations envoyées avec succès au broker MQTT."
        else
            echo "Erreur lors de l'envoi des informations au broker MQTT."
        fi
    else
        echo "Aucune donnée valide à envoyer."
    fi

    # Attendre 4 secondes avant de répéter
    sleep 4
done
