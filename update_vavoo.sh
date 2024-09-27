#!/bin/bash

# Télécharger le fichier JSON directement depuis l'URL
curl -o /var/www/html/channel.json https://vavoo.to/channels

# Vérifier si le téléchargement a réussi
if [ $? -eq 0 ]; then
  echo "Téléchargement réussi : /var/www/html/channel.json"
else
  echo "Erreur : échec du téléchargement."
  exit 1
fi
