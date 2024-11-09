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
filtered_data=$(echo "$json_data" | jq -r --arg ip "$decoded_ip" \
    '.clients[] | select(.ip == $ip and (.type == "flv-play" or .type == "hls-play")) | "\(.id) \(.alive)"')

# Trier les données par ordre croissant de 'alive'
sorted_data=$(echo "$filtered_data" | sort -k2,2n)

# Nombre de lignes dans la liste triée
num_lines=$(echo "$sorted_data" | wc -l)

# Affichage des ID et des états 'alive' triés, à partir de la ligne spécifiée par limite
if [ "$limite" -ge "$num_lines" ]; then
    echo "Pas assez d'éléments pour afficher à partir de la ligne $limite."
else
    echo "ID et état 'alive' triés par ordre croissant, à partir de la ligne $limite :"
    data_to_delete=$(echo "$sorted_data" | tail -n +$((limite + 1)))
    echo "$data_to_delete"

    # Suppression pour chaque ID restant
    while read -r id alive; do
        echo "Suppression du client avec ID : $id et état 'alive' : $alive"
        curl -v -X DELETE "http://127.0.0.1:1985/api/v1/clients/$id"
    done <<< "$data_to_delete"
fi
