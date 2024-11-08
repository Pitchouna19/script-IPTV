#!/bin/bash

# Récupère les arguments : IP décodée et limite du nombre de lignes
decoded_ip="$1"
limite="$2"

# URL de l'API
url="http://127.0.0.1:1985/api/v1/clients/"

# Récupération du JSON à partir de l'API
json_data=$(curl -s "$url")

# Vérification que la requête a réussi
if [ $? -ne 0 ]; then
    echo "Erreur lors de la récupération des données depuis l'API."
    exit 1
fi

# Filtrage du JSON avec jq pour sélectionner les clients correspondant aux critères
filtered_ids=$(echo "$json_data" | jq -r --arg ip "$decoded_ip" '.clients[] | select(.ip == $ip and (.type == "flv-play" or .type == "hls-play")) | .id // "0"')

# Inversion de l'ordre des IDs
reversed_ids=$(echo "$filtered_ids" | tac)

# Nombre de lignes dans la liste inversée
num_lines=$(echo "$reversed_ids" | wc -l)

# Affichage des IDs inversés, à partir de la ligne spécifiée par limite
if [ "$limite" -ge "$num_lines" ]; then
    # Si la limite est supérieure ou égale au nombre d'éléments, ne rien afficher
    echo "Pas assez d'éléments pour afficher à partir de la ligne $limite."
else
    # Afficher à partir de la ligne spécifiée par limite
    echo "IDs filtrés et inversés, à partir de la ligne $limite :"
    # Afficher à partir de la ligne spécifiée par limite (en ignorant les premières lignes)
    filtered_ids_to_delete=$(echo "$reversed_ids" | tail -n +$((limite + 1)))
    echo "$filtered_ids_to_delete"

    # Suppression pour chaque ID restant
    for id in $filtered_ids_to_delete; do
        echo "Suppression du client avec ID : $id"
        curl -v -X DELETE "http://127.0.0.1:1985/api/v1/clients/$id"
    done
fi
