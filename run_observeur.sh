#!/bin/bash
# Script pour écouter sur le topic /client/monitoring et maintenir un tableau JSON unique basé sur l'IP

JSON_FILE="/var/lib/mosquitto/map.json"
BROKER_IP="PPP"
MQTT_USER="USPAS"
MQTT_PASS="PASW"
TOPIC="/client/infomap"

# Initialiser le fichier JSON vide s'il n'existe pas ou le vider au démarrage
if [[ ! -f $JSON_FILE ]]; then
    echo '[]' | sudo tee $JSON_FILE > /dev/null
else
    : > "$JSON_FILE"  # Vider le fichier JSON au démarrage
fi
sudo chmod 666 $JSON_FILE  # S'assurer que le fichier est accessible en écriture

# Fonction pour mettre à jour ou ajouter un client dans le tableau JSON
update_map() {
    local message="$1"
    local ip status

    # Extraire l'IP et le statut du message JSON
    ip=$(echo "$message" | grep -oP '"ip": *"\K[^"]*')
    status=$(echo "$message" | grep -oP '"status": *"\K[^"]*')

    echo "IP extrait : $ip"
    echo "Status extrait : $status"

    # Lire le fichier JSON et le stocker dans une variable
    current_json=$(<"$JSON_FILE")

    echo "JSON actuel : $current_json"

    # Vérifier si le JSON est valide
    if [[ "$current_json" == "" ]]; then
        current_json="[]"
    fi

    # Vérifier si l'IP existe déjà dans le JSON
    if echo "$current_json" | grep -q "\"ip\": *\"$ip\""; then
        # Mettre à jour le statut
        updated_json=$(echo "$current_json" | sed "s/\"ip\": *\"$ip\", *\"status\": *\"[^\"]*\"/\"ip\": \"$ip\", \"status\": \"$status\"/")
    else
        # Ajouter un nouvel enregistrement
        if [[ "$current_json" == "[]" ]]; then
            updated_json="[{\"ip\": \"$ip\", \"status\": \"$status\"}]"
        else
            updated_json="${current_json%?}, {\"ip\": \"$ip\", \"status\": \"$status\"}]"
        fi
    fi

    echo "JSON mis à jour : $updated_json"

    # Écrire le JSON mis à jour dans le fichier
    echo "$updated_json" | sudo tee $JSON_FILE > /dev/null

    # Vérifier le contenu du fichier JSON après mise à jour
    echo "Contenu du fichier JSON après mise à jour :"
    cat $JSON_FILE
}

# Écouter les messages sur le topic et traiter chaque message
mosquitto_sub -h "$BROKER_IP" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$TOPIC" | while read -r message
do
    # Afficher le message reçu pour déboguer
    echo "Message reçu : $message"

    # Mettre à jour ou ajouter le client dans le tableau JSON
    update_map "$message"
done
