#!/bin/bash

# Fonction pour afficher un message en vert
function echo_green() {
    echo -e "\e[32m$1\e[0m"
}

function echo_red() {
    echo -e "\e[31m$1\e[0m"
}

# Affichage du motif ASCII pour "RST-PI"
clear
echo "#############################################"
echo "#                                           #"
echo "#     ____  ____  ______   _____  ____      #"
echo "#    |  _ \|  _ \|  _ \ \ / / _ \|  _ \     #"
echo "#    | |_) | |_) | |_) \ V / | | | |_) |    #"
echo "#    |  __/|  __/|  _ < | || |_| |  __/     #"
echo "#    |_|   |_|   |_| \_\|_| \___/|_|        #"
echo "#                                           #"
echo "#             RST-PI Installer              #"
echo "#############################################"
echo

# Présentation du choix d'installation
echo "Veuillez choisir le mode d'installation :"
echo "1) Installation en mode Client"
echo "2) Installation en mode Serveur"
echo "q) Quitter"

# Lecture du choix de l'utilisateur
read -p "Entrez votre choix [1/2/q] : " choix

# Fonction commune : Mise à jour du système
function mise_a_jour_systeme() {
    echo "Mise à jour du système en cours..."
    sudo apt update && sudo apt upgrade -y
    echo_green "#############################################"
    echo_green "#                                           #"
    echo_green "#        Système Linux Ubuntu à jour        #"
    echo_green "#                                           #"
    echo_green "#############################################"
    sleep 5
}

# Fonction commune : Installation des dépendances
function installation_dependances() {
    echo "Installation des dépendances en cours..."
    sudo apt install -y unzip curl git jq sysstat bc sed
    echo_green "#############################################"
    echo_green "#                                           #"
    echo_green "#      Installation des dépendances OK      #"
    echo_green "#                                           #"
    echo_green "#############################################"
    sleep 5
}

# Fonction commune : Installation de Mosquitto
function installation_mosquitto() {
    echo "Installation de Mosquitto en cours..."
    sudo apt install -y mosquitto mosquitto-clients || { echo_red "Erreur lors de l'installation de Mosquitto"; exit 1; }
    echo_green "#############################################"
    echo_green "#                                           #"
    echo_green "# Installation Mosquitto Client/Serveur OK  #"
    echo_green "#                                           #"
    echo_green "#############################################"
    echo "Demarage de Mosquitto en cours..."
    sleep 1
    sudo systemctl start mosquitto
    sudo systemctl enable mosquitto
    sleep 5

    if [ "$(sudo systemctl is-active mosquitto)" = "active" ]; then

        echo_green "Serveur Mosquitto installé et actif."
    else
        echo_red "L'installation de Mosquitto a échoué."
    fi
    
    
    
    sleep 5
}

# Fonction commune : Installation de Mosquitto
function installation_Docker() {
    echo "Installation de Docker en cours..."
    # Désinstallation des anciennes versions
    sleep 2

    echo "Désinstallation des anciennes versions de Docker..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        sudo apt-get remove $pkg
    done

    # Installation des dépendances
    echo "Installation des dépendances..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl

    # Ajout de la clé GPG officielle de Docker
    echo "Ajout de la clé GPG officielle de Docker..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Ajout du dépôt Docker aux sources APT
    echo "Ajout du dépôt Docker aux sources APT..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Mise à jour des paquets et installation de Docker
    echo "Mise à jour des paquets et installation de Docker..."
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Vérification de l'installation
    echo "Vérification de l'installation de Docker..."
    
    echo_green "#############################################"
    echo_green "#                                           #"
    echo_green "#           Installation Docker OK          #"
    echo_green "#                                           #"
    echo_green "#############################################"


    if sudo docker run hello-world; then
        echo_green "Docker a été installé avec succès."
    else
        echo_red "L'installation de Docker a échoué."
    fi
       
    sleep 5
}

function installation_srs() {    
    echo "Démarrage de l'installation [SRS Real-Time Stream] sur le Client..."
    sleep 2

    # Copie du fichier client_report.sh dans /usr/local/bin
    echo "Copie du fichier start-srs.sh vers /usr/local/bin..."
    sudo cp start-srs.sh /usr/local/bin/start-srs.sh

    # Rendre le script exécutable
    sudo chmod +x /usr/local/bin/start-srs.sh

    # Copie du fichier srs.service dans /usr/local/bin
    echo "Copie du fichier srs.service vers /etc/systemd/system/..."
    sudo cp srs.service /etc/systemd/system/srs.service

    # Activer et démarrer le service
    echo "Activation et démarrage du service srs.service..."
    sudo systemctl enable srs.service
    sudo systemctl start srs.service
    

    echo_green "#######################################################"
    echo_green "#                                                     #"
    echo_green "#          Configuration de [SRS] terminée.           #"
    echo_green "#                                                     #"
    echo_green "#######################################################"
    echo


    sleep 5    
}

# Fonction commune : Installation de Nginx
function installation_nginx() {
    echo "Installation de Ngin en cours..."
    sudo apt install -y nginx
    echo_green "#############################################"
    echo_green "#                                           #"
    echo_green "#       Installation Nginx Serveur OK       #"
    echo_green "#                                           #"
    echo_green "#############################################"
    echo "Demarage de Nginx en cours..."
    sleep 1
    # Configurer Nginx pour écouter sur le port 9090
    sudo bash -c "cat > /etc/nginx/sites-available/clients << EOF
server {
    listen 9090;
    server_name localhost;

    location / {
        root /var/www/html;
        index index.html;
    }

    location /clients.json {
        alias /var/lib/mosquitto/clients.json;
        default_type application/json;
        add_header Access-Control-Allow-Origin *;
    }
}
EOF"

    sleep 1

    # Activer cette nouvelle configuration
    sudo ln -s /etc/nginx/sites-available/clients /etc/nginx/sites-enabled/

    # Création de l'interface AJAX
    sudo mkdir -p /var/www/html
    sudo bash -c 'echo "[]" > /var/www/html/clients.json'
    sudo ln -s /var/lib/mosquitto/clients.json /var/www/html/clients.json
    # Copie de index.html vers var/www/html/
    sudo cp index.html /var/www/html/

    sudo systemctl enable nginx                
    sudo systemctl start nginx
    sleep 5

    if nginx -v &> /dev/null; then
        echo_green "Nginx installé avec succès."        
    else
        echo_red "L'installation de Nginx a échoué."
    fi
    
    
    
    sleep 5
}

# Fonction spécifique : Installation en mode Client
function installation_client() {
    echo "Démarrage de l'installation [Reporting] en mode Client..."
    sleep 2

    echo_green "#############################################"
    echo_green "#      Entrer les Info IP / USER / PASS  :  #"
    echo_green "#############################################"
    echo # Nouvelle ligne pour rendre l'affichage plus propre
    
    # Demander les trois questions et stocker les réponses
    read -p "Quelle est l'IP du Serveur Broker : " serveur_ip
    read -p "Quel est le nom d'utilisateur : " utilisateur    
    echo # Nouvelle ligne pour rendre l'affichage plus propre


    sudo mosquitto_passwd -c /etc/mosquitto/passwordfile "$utilisateur"
    sudo bash -c 'grep -qxF "allow_anonymous false" /etc/mosquitto/mosquitto.conf || echo "allow_anonymous false" >> /etc/mosquitto/mosquitto.conf'
    sudo bash -c 'grep -qxF "password_file /etc/mosquitto/passwordfile" /etc/mosquitto/mosquitto.conf || echo "password_file /etc/mosquitto/passwordfile" >> /etc/mosquitto/mosquitto.conf'
    read -s -p "Quel est le mot de passe precedant [Encore SVP] : " mot_de_passe
    
    sudo systemctl restart mosquitto
    
    echo_green "#######################################################"
    echo_green "#                                                     #"
    echo_green "#  Configuration de la sécurité du [Broker] terminée. #"
    echo_green "#                                                     #"
    echo_green "#######################################################"
    echo
    sleep 2

    # Copie du fichier client_report.sh dans /usr/local/bin
    echo "Copie du fichier client_report.sh vers /usr/local/bin..."
    sudo cp client_report.sh /usr/local/bin/client_report.sh
    
    # Remplacer les termes 'PPP', 'USPAS', et 'PASW' dans le fichier copié
    echo "Modification des variables dans le fichier /usr/local/bin/client_report.sh..."
    sudo sed -i "s/PPP/$serveur_ip/g" /usr/local/bin/client_report.sh
    sudo sed -i "s/USPAS/$utilisateur/g" /usr/local/bin/client_report.sh
    sudo sed -i "s/PASW/$mot_de_passe/g" /usr/local/bin/client_report.sh

    # Rendre le script exécutable
    sudo chmod +x /usr/local/bin/client_report.sh

    # Copie du fichier client_mqtt.service dans /etc/systemd/system/
    echo "Copie du fichier client_mqtt.service vers /etc/systemd/system/..."
    sudo cp client_mqtt.service /etc/systemd/system/client_mqtt.service

    # Activer et démarrer le service
    echo "Activation et démarrage du service client_mqtt.service..."
    sudo systemctl enable client_mqtt.service
    sudo systemctl start client_mqtt.service

    echo_green "#######################################################"
    echo_green "#                                                     #"
    echo_green "#  Installation du mode Client [Reporting] terminée   #"
    echo_green "#                                                     #"
    echo_green "#######################################################"

    sleep 5

    echo "Démarrage de l'installation [Monitoring] en mode Client..."    

    # Copie du fichier client_report.sh dans /usr/local/bin
    echo "Copie du fichier client_report.sh vers /usr/local/bin..."
    sudo cp client_report_monitor.sh /usr/local/bin/client_report_monitor.sh
    
    # Remplacer les termes 'PPP', 'USPAS', et 'PASW' dans le fichier copié
    echo "Modification des variables dans le fichier /usr/local/bin/client_report_monitor.sh..."
    sudo sed -i "s/PPP/$serveur_ip/g" /usr/local/bin/client_report_monitor.sh
    sudo sed -i "s/USPAS/$utilisateur/g" /usr/local/bin/client_report_monitor.sh
    sudo sed -i "s/PASW/$mot_de_passe/g" /usr/local/bin/client_report_monitor.sh

    # Rendre le script exécutable
    sudo chmod +x /usr/local/bin/client_report_monitor.sh

    # Copie du fichier client_mqtt.service dans /etc/systemd/system/
    echo "Copie du fichier client_mqtt.service vers /etc/systemd/system/..."
    sudo cp client_mqtt_monitor.service /etc/systemd/system/client_mqtt_monitor.service

    # Activer et démarrer le service
    echo "Activation et démarrage du service client_mqtt.service..."
    sudo systemctl enable client_mqtt_monitor.service
    sudo systemctl start client_mqtt_monitor.service

    echo_green "#######################################################"
    echo_green "#                                                     #"
    echo_green "#  Installation du mode Client [Monitoring] terminée  #"
    echo_green "#                                                     #"
    echo_green "#######################################################"

    sleep 5
}

# Fonction spécifique : Installation en mode Serveur
function installation_serveur() {

    echo "Démarrage de l'installation de la securité Brocker..."

    echo "Démarrage de l'installation [listener] en mode Serveur..."

    # Demander les trois questions et stocker les réponses
    read -p "Quelle est l'IP du Serveur Broker : " serveur_ip
    read -p "Quel est le nom d'utilisateur : " utilisateur
    echo # Nouvelle ligne pour rendre l'affichage plus propre

    sudo mosquitto_passwd -c /etc/mosquitto/passwordfile "$utilisateur"
    sudo bash -c 'grep -qxF "allow_anonymous false" /etc/mosquitto/mosquitto.conf || echo "allow_anonymous false" >> /etc/mosquitto/mosquitto.conf'
    sudo bash -c 'grep -qxF "password_file /etc/mosquitto/passwordfile" /etc/mosquitto/mosquitto.conf || echo "password_file /etc/mosquitto/passwordfile" >> /etc/mosquitto/mosquitto.conf'
    read -s -p "Quel est le mot de passe precedant [Encore SVP] : " mot_de_passe
    
    sudo systemctl restart mosquitto

    echo_green "#######################################################"
    echo_green "#                                                     #"
    echo_green "#  Configuration de la sécurité du [Broker] terminée. #"
    echo_green "#                                                     #"
    echo_green "#######################################################"
    echo
    sleep 2

    # Copie du fichier client_report.sh dans /usr/local/bin
    echo "Copie du fichier mqtt_server_listener.sh vers /usr/local/bin..."
    sudo cp mqtt_server_listener.sh /usr/local/bin/mqtt_server_listener.sh
    
    # Remplacer les termes 'PPP', 'USPAS', et 'PASW' dans le fichier copié
    echo "Modification des variables dans le fichier /usr/local/bin/mqtt_server_listener.sh..."
    sudo sed -i "s/PPP/$serveur_ip/g" /usr/local/bin/mqtt_server_listener.sh
    sudo sed -i "s/USPAS/$utilisateur/g" /usr/local/bin/mqtt_server_listener.sh
    sudo sed -i "s/PASW/$mot_de_passe/g" /usr/local/bin/mqtt_server_listener.sh

    # Rendre le script exécutable
    sudo chmod +x /usr/local/bin/mqtt_server_listener.sh

    # Copie du fichier client_mqtt.service dans /etc/systemd/system/
    echo "Copie du fichier client_mqtt.service vers /etc/systemd/system/..."
    sudo cp mqtt_server_listener.service /etc/systemd/system/mqtt_server_listener.service

    # Activer et démarrer le service
    echo "Activation et démarrage du service mqtt_server_listener.service..."
    sudo systemctl enable mqtt_server_listener.service
    sudo systemctl start mqtt_server_listener.service

    echo_green "#######################################################"
    echo_green "#                                                     #"
    echo_green "#  Installation du mode Serveur [Listener] terminée   #"
    echo_green "#                                                     #"
    echo_green "#######################################################"

    sleep 5

}

# Exécution des étapes en fonction du choix
case $choix in
    1)
        mise_a_jour_systeme
        installation_dependances
        installation_mosquitto
        installation_client
        installation_Docker
        installation_srs
        ;;
    2)
        mise_a_jour_systeme
        installation_dependances
        installation_mosquitto
        installation_serveur
        installation_nginx
        ;;
    q)
        echo "Installation annulée. À bientôt!"
        exit 0
        ;;
    *)
        echo "Choix invalide. Veuillez exécuter à nouveau le script."
        ;;
esac
