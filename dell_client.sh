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

# Affichage des IDs inversés, limité au nombre de lignes spécifié
if [ -z "$limite" ] || [ "$limite" -le 0 ]; then
    # Si aucune limite n'est spécifiée ou si la limite est invalide, afficher toutes les lignes
    echo "IDs filtrés et inversés :"
    echo "$reversed_ids"
else
    # Limiter le nombre de lignes affichées
    echo "IDs filtrés et inversés (limité à $limite lignes) :"
    reversed_ids=$(echo "$reversed_ids" | head -n "$limite")
    echo "$reversed_ids"
fi

# Effectuer la suppression pour chaque ID restant
for id in $reversed_ids; do
    echo "Suppression du client avec ID : $id"
    curl -v -X DELETE "http://127.0.0.1:1985/api/v1/clients/$id"
done
