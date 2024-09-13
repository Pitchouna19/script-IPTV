#!/bin/bash

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour vérifier si un programme est installé
check_installed() {
    if [ "$1" = "mosquitto" ]; then
        server_installed=false
        client_installed=false
        
        if command -v mosquitto &> /dev/null; then
            server_installed=true
        fi
        
        if command -v mosquitto_pub &> /dev/null; then
            client_installed=true
        fi
        
        if $server_installed && $client_installed; then
            echo -e "${GREEN}[CLIENT ET SERVEUR INSTALLÉS]${NC}"
        elif $server_installed; then
            echo -e "${GREEN}[SERVEUR INSTALLÉ]${NC} ${RED}[CLIENT NON INSTALLÉ]${NC}"
        elif $client_installed; then
            echo -e "${GREEN}[CLIENT INSTALLÉ]${NC} ${RED}[SERVEUR NON INSTALLÉ]${NC}"
        else
            echo -e "${RED}[NON INSTALLÉ]${NC}"
        fi
    else
        if command -v $1 &> /dev/null; then
            echo -e "${GREEN}[INSTALLÉ]${NC}"
        else
            echo -e "${RED}[NON INSTALLÉ]${NC}"
        fi
    fi
}

# [Le reste des fonctions reste inchangé]

# Liste des options avec indication d'installation
echo "Choisissez ce que vous souhaitez installer :"
echo -n "1) Installer nginx "; check_installed nginx
echo -n "2) Installer Mosquitto (MQTT) "; check_installed mosquitto
echo -n "3) Installer curl "; check_installed curl
echo -n "4) Installer git "; check_installed git
echo -n "5) Installer Docker "; check_installed docker
echo -n "6) Installer SRS (nécessite Docker) "; check_installed docker
echo "7) Installer tout"
echo "8) Sortir Exit"

read -p "Entrez le numéro de votre choix : " choice

# Exécution selon le choix
case $choice in
    1)
        install_nginx
        ;;
    2)
        install_mosquitto
        ;;
    3)
        install_curl
        ;;
    4)
        install_git
        ;;
    5)
        install_docker
        ;;
    6)
        install_srs
        ;;
    7)
        install_nginx
        install_mosquitto
        install_curl
        install_git
        install_docker
        install_srs
        ;;
    8)
        echo "Sortie du script."
        exit 0
        ;;
    *)
        echo "Choix invalide. Veuillez relancer le script et sélectionner un numéro valide."
        ;;
esac

echo "Installation terminée."
