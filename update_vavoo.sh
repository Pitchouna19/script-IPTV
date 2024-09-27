#!/bin/bash

# Vérifier si un argument a été fourni
if [ -z "$1" ]; then
  echo "Erreur : aucune URL fournie."
  echo "Usage: $0 <URL>"
  exit 1
fi

# Télécharger le fichier JSON et le sauvegarder
curl -o /var/www/html/channel.json "$1"
