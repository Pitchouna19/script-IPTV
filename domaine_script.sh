#!/bin/bash

# Chemin du fichier xtream.json
XTREAM_JSON="/var/www/html/xtream.json"

# Vérifier si le fichier existe
if [[ ! -f "$XTREAM_JSON" ]]; then
  echo "Erreur : le fichier xtream.json n'existe pas à l'emplacement $XTREAM_JSON"
  DOMAIN = '_'
  export DOMAIN
  exit 1
fi

# Extraire le domaine depuis le fichier xtream.json
DOMAIN=$(jq -r '.domaine' "$XTREAM_JSON" 2>/dev/null)

# Vérifier si jq a réussi à extraire la valeur
if [[ -z "$DOMAIN" || "$DOMAIN" == "null" ]]; then
  echo "Erreur : impossible d'extraire le domaine depuis $XTREAM_JSON"
  DOMAIN = '_'
  export DOMAIN
  exit 1
fi

# Supprimer le préfixe http:// ou https://
DOMAIN=$(echo "$DOMAIN" | sed 's|http://||;s|https://||')

# Exporter la variable
export DOMAIN
echo "Domaine extrait et exporté : $DOMAIN"

# Redémarrer OpenResty pour appliquer la nouvelle variable d'environnement
#sudo systemctl restart openresty
