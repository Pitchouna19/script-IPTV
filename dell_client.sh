#!/bin/bash

# Récupère les arguments
decoded_ip="$1"
limite="$2"

# Exécute la commande avec les arguments donnés
curl -s http://127.0.0.1:1985/api/v1/clients/ | \
jq -r --arg ip "$decoded_ip" '.clients[] | select(.ip == $ip and (.type == "flv-play" or .type == "m3u8-play")) | .id // "0"' | \
{ readarray -t ids; (( ${#ids[@]} > limite )) && printf '%s\n' "${ids[@]:$limite}" || printf '%s\n' "${ids[@]}"; } | \
xargs -I {} curl -v -X DELETE http://127.0.0.1:1985/api/v1/clients/{} && echo ""
