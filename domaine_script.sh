#!/bin/bash

# Chemin du fichier xtream.json
XTREAM_JSON="/var/www/html/xtream.json"

# Extraire le domaine depuis le fichier xtream.json
export DOMAIN=$(jq -r '.domaine' "$XTREAM_JSON" | sed 's|http://||;s|https://||')

# Redémarrer OpenResty pour appliquer la nouvelle variable d'environnement
sudo systemctl restart openresty
