#!/bin/bash
# Script pour envoyer les informations du client au broker MQTT

BROKER_IP="PPP"
MQTT_USER="USPAS"
MQTT_PASS="PASW"
TOPIC="/client/monitoring"

CACHE_FILE="geo_cache.json"

# Fonction pour lire le cache
read_cache() {
    if [ -f "$CACHE_FILE" ]; then
        jq . "$CACHE_FILE"
    else
        echo '{}'
    fi
}

# Fonction pour écrire dans le cache
write_cache() {
    echo "$1" | jq . > "$CACHE_FILE"
}

# Vérifier si le fichier de cache existe, sinon le créer
if [ ! -f "$CACHE_FILE" ]; then
    echo '{}' > "$CACHE_FILE"
fi

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

        #JSON_LIST="$1"

        # Vérifier si la liste "clients" est vide
        clients_count=$(echo "$JSON_LIST" | jq '.clients | length')

        if [ "$clients_count" -eq 0 ]; then
            # Si la liste "clients" est vide, on affiche le message tel quel
            echo "$JSON_LIST"            
        fi

        # Lire le cache
        cache=$(read_cache)

        echo "JSON_LIST : $JSON_LIST"

        # Extraire les clés dynamiques (par exemple, "192.168.1.39")
        dynamic_keys=$(echo "$JSON_LIST" | jq -r 'keys[]')

        # Vérifier si dynamic_keys est null ou vide
        if [ -z "$dynamic_keys" ]; then
            echo "No dynamic keys found in the JSON_LIST"
            exit 1
        fi

        # Boucler sur chaque clé dynamique
        for key in $dynamic_keys; do
            # Extraire les adresses IP des clients pour chaque clé dynamique
            ip_addresses=$(echo "$JSON_LIST" | jq -r --arg key "$key" '.[$key].clients[].ip')

            # Vérifier si ip_addresses est null ou vide
            if [ -z "$ip_addresses" ]; then
                echo "No IP addresses found in the JSON_LIST for key $key"
                continue
            fi

            # Boucler sur chaque adresse IP et obtenir les informations de géolocalisation
            for ip in $ip_addresses; do
                echo "Processing IP: $ip"

                echo "#################################################################"

                # Vérifier si l'adresse IP est locale
                if [[ "$ip" == 10.* || "$ip" == 172.* || "$ip" == 192.168.* ]]; then
                    echo "IP $ip is local, skipping processing"
                    country="-"
                else
                    # Vérifier si l'adresse IP est dans le cache
                    country=$(echo "$cache" | jq -r --arg ip "$ip" '.[$ip].country // "-"')

                    if [ "$country" == "-" ]; then
                        # Si l'adresse IP n'est pas dans le cache, faire l'appel curl
                        echo "IP $ip not found in cache, making API call..."
                        geo_info=$(curl -s "https://get.geojs.io/v1/ip/geo/$ip.json")
                        country=$(echo "$geo_info" | jq -r '.country // "-"')

                        # Mettre à jour le cache
                        cache=$(echo "$cache" | jq --arg ip "$ip" --arg country "$country" '. + {($ip): {country: $country}}')
                        write_cache "$cache"
                    else
                        echo "IP $ip found in cache"
                    fi
                fi

                echo "Country for IP $ip: $country"

                # Ajouter le pays au JSON original
                JSON_LIST=$(echo "$JSON_LIST" | jq --arg ip "$ip" --arg country "$country" --arg key "$key" '
                    .[$key].clients |= map(if .ip == $ip then . + {country: $country} else . end)
                ')
            done
        done

        # Afficher le JSON mis à jour
        echo "$JSON_LIST"

        # Vérifier si la commande jq a réussi
        if [ $? -ne 0 ]; then
            echo "Erreur lors du traitement JSON avec jq."
            exit 1
        fi

        # Formater le JSON en une seule ligne
        JSON_LIST_SINGLE_LINE=$(echo "$JSON_LIST" | jq -c .)

        # Publier le JSON formaté sur le broker MQTT
        mosquitto_pub -h "$BROKER_IP" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$TOPIC" -m "$JSON_LIST_SINGLE_LINE"

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
