#!/bin/bash

# Fonction pour afficher un message en vert
function echo_green() {
    echo -e "\e[32m$1\e[0m"
}

function echo_red() {
    echo -e "\e[31m$1\e[0m"
}

function echo_orange() {
    echo -e "\e[38;5;214m$1\e[0m"
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

function installation_gestremer() {
    echo "Installation GStreamer en cours..."
    sudo apt update && sudo apt upgrade -y && \
    sudo apt install -y gstreamer1.0-tools gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-base-apps \
    gstreamer1.0-plugins-ugly gstreamer1.0-libav libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev

    echo_green "#############################################"
    echo_green "#                                           #"
    echo_green "#    'Gestremer' installer correctement     #"
    echo_green "#                                           #"
    echo_green "#############################################"
    sleep 5
}

function firewall_client_open() {
    if ! command -v ufw &> /dev/null; then
        echo "UFW n'est pas installé. Installation en cours..."
        sudo apt install -y ufw || {
            echo "Erreur lors de l'installation de UFW."
            return 1
        }
    fi

    echo "Activation du firewall..."
    sudo ufw enable || {
        echo "Erreur lors de l'activation du firewall."
        return 1
    }

    local ports=(8080 9095 1985 1883 22)
    for port in "${ports[@]}"; do
        echo "Ouverture du port $port..."
        sudo ufw allow "$port" || {
            echo "Erreur lors de l'ouverture du port $port."
            return 1
        }

        # Ajouter une pause pour s'assurer que le changement est pris en compte
        sleep 2

        # Vérifier si le port est bien ouvert
        if sudo ufw status | grep -qE "^$port\s+ALLOW"; then
            echo "Le port $port est bien ouvert."
        else
            echo "Erreur : Le port $port n'a pas été correctement ouvert."
            return 1
        fi
    done

    echo "Tous les ports ont été ouverts avec succès."
    return 0
}

function firewall_serveur_open() {
    if ! command -v ufw &> /dev/null; then
        echo "UFW n'est pas installé. Installation en cours..."
        sudo apt install -y ufw || {
            echo "Erreur lors de l'installation de UFW."
            return 1
        }
    fi

    echo "Activation du firewall..."
    sudo ufw enable || {
        echo "Erreur lors de l'activation du firewall."
        return 1
    }

    local ports=(9090 8080 1985 1883 22)
    for port in "${ports[@]}"; do
        echo "Ouverture du port $port..."
        sudo ufw allow "$port" || {
            echo "Erreur lors de l'ouverture du port $port."
            return 1
        }

        # Ajouter une pause pour s'assurer que le changement est pris en compte
        sleep 2

        # Vérifier si le port est bien ouvert
        if sudo ufw status | grep -qE "^$port\s+ALLOW"; then
            echo "Le port $port est bien ouvert."
        else
            echo "Erreur : Le port $port n'a pas été correctement ouvert."
            return 1
        fi
    done

    echo "Tous les ports ont été ouverts avec succès."
    return 0
}

# Fonction commune : Installation de Python3 et dependance
function installation_python() {
    # Vérification de l'installation de Python3
    if command -v python3 &> /dev/null; then
        echo "Python3 est déjà installé."
    else
        echo "Installation de Python3 en cours..."
        sudo apt install python3 -y
        if [ $? -ne 0 ]; then
            echo "Échec de l'installation de Python3."
            exit 1
        fi
        echo_green "#############################################"
        echo_green "#                                           #"
        echo_green "#          Installation Python OK           #"
        echo_green "#                                           #"
        echo_green "#############################################"
        sleep 5
    fi

    # Vérification de l'installation de pip
    if command -v pip3 &> /dev/null; then
        echo "pip3 est déjà installé."
    else
        echo "Installation de pip3 en cours..."
        sudo apt install python3-pip -y
        if [ $? -ne 0 ]; then
            echo "Échec de l'installation de pip3."
            exit 1
        fi
        echo_green "#############################################"
        echo_green "#                                           #"
        echo_green "#          Installation pip OK               #"
        echo_green "#                                           #"
        echo_green "#############################################"
        sleep 5
    fi

    # Vérification de l'installation de Flask
    if python3 -c "import flask" &> /dev/null; then
        echo "Flask est déjà installé."
    else
        echo "Installation de Flask en cours..."
        sudo pip3 install flask
        if [ $? -ne 0 ]; then
            echo "Échec de l'installation de Flask."
            exit 1
        fi
    fi

    # Vérification de l'installation de Requests
    if python3 -c "import requests" &> /dev/null; then
        echo "Requests est déjà installé."
    else
        echo "Installation de Requests en cours..."
        sudo pip3 install requests
        if [ $? -ne 0 ]; then
            echo "Échec de l'installation de Requests."
            exit 1
        fi
    fi

    # Création du dossier utilus s'il n'existe pas déjà
    if [ ! -d /root/utilus ]; then
        sudo mkdir /root/utilus
        echo "Dossier utilus créé."
    else
        echo "Le dossier utilus existe déjà."
    fi

    # Copie du script util_url.py dans le dossier
    echo "Copie du script util_url.py dans /root/utilus..."
    sudo cp util_url.py /root/utilus/
    
    echo "Installation du Service Util_url au démarrage..."
    sudo cp util_url.service /etc/systemd/system/util_url.service
    sleep 2

    # Activer et démarrer le service
    echo "Activation et démarrage du service util_url.service..."
    sudo systemctl enable util_url.service
    sudo systemctl start util_url.service
    sleep 2

    echo_green "#############################################"
    echo_green "#                                           #"
    echo_green "#    Installation Python et Flask  [OK]     #"
    echo_green "#                                           #"
    echo_green "#############################################"
}

# Fonction commune : Installation des dépendances
function installation_node() {
    echo "Installation du serveur Node cours..."
    sudo curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -     
    sleep 5
    sudo apt install nodejs
    sleep 5
    echo "Installation du serveur Node Express en cours..."
    cd /var/www/html
    sudo npm install express
    sleep 5
    echo "Installation du serveur Node Cors en cours..."
    sudo npm install cors
    sleep 5
    cd /root/script-IPTV/
    echo "Suite..."
    echo "Copy du fichier server.js dans /var/www/html/"
    sudo cp server.js /var/www/html/
    sleep 3
    echo "Installation du Service NodeJs au demarage..."
    sudo cp node.service /etc/systemd/system/node.service
    sleep 2
     # Activer et démarrer le service
    echo "Activation et démarrage du service node.service..."
    sudo systemctl enable node.service
    sudo systemctl start node.service
    
    
    if command -v node > /dev/null 2>&1; then
        echo_green "#############################################"
        echo_green "#                                           #"
        echo_green "#      Installation du serveur Node  OK     #"
        echo_green "#                                           #"
        echo_green "#############################################"
    else        
        echo_red "#############################################"
        echo_red "#                                           #"
        echo_red "#      L'installation Node a échoué.        #"
        echo_red "#                                           #"
        echo_red "#############################################"
fi
}

# Fonction commune : Installation des dépendances
function installation_dependances() {
    echo "Installation des dépendances en cours..."
    sudo apt install -y unzip curl git jq sysstat bc sed ffmpeg software-properties-common ufw
    echo_green "#############################################"
    echo_green "#                                           #"
    echo_green "#      Installation des dépendances OK      #"
    echo_green "#                                           #"
    echo_green "#############################################"
    sleep 5
}

# Fonction Serveur : Installation de Kick-Off
function installation_kickoff() {
    echo "Installation de kick-off en cours..."
    echo "Copie du fichier kickoff.sh vers /usr/local/bin..."
    sudo cp kickoff.sh /usr/local/bin/kickoff.sh
     
    # Rendre le script exécutable
    sudo chmod +x /usr/local/bin/kickoff.sh

    # Copie du fichier kickoff.service dans /etc/systemd/system/
    echo "Copie du fichier kickoff.service vers /etc/systemd/system/..."
    sudo cp kickoff.service /etc/systemd/system/kickoff.service

    # Activer et démarrer le service
    echo "Activation et démarrage du service kickoff.service..."
    sudo systemctl enable kickoff.service
    sudo systemctl start kickoff.service
    
    echo_green "#############################################"
    echo_green "#                                           #"
    echo_green "#        Installation de kickoff  OK        #"
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
    sudo mkdir -p /usr/local/etc/srs && sudo cp srs.conf /usr/local/etc/srs/srs.conf
    
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

# Fonction commune : Installation de OpenResty
function installation_openresty_server() {
    echo "Installation d'OpenResty en cours..."
    sudo apt-get -y install --no-install-recommends wget gnupg ca-certificates lsb-release
    sudo wget -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
    echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" \
     | sudo tee /etc/apt/sources.list.d/openresty.list
    sudo apt update
    sudo apt install -y openresty
    echo_green "#############################################"
    echo_green "#                                           #"
    echo_green "#       Installation OpenResty Serveur OK   #"
    echo_green "#                                           #"
    echo_green "#############################################"
    echo "Démarrage d'OpenResty en cours..."
    sleep 1
    # Copie du nginx.conf vers /etc/openresty/
    sudo cp nginx.conf /etc/openresty/
    # Queleque creation de dossier
    sudo mkdir /etc/openresty/sites-enabled
    sudo mkdir /etc/openresty/sites-available
    # Configurer OpenResty pour écouter sur le port 9090
    echo "Copie du fichier 'clients'...dans /etc/openresty/sites-available/"
    sudo cp clients /etc/openresty/sites-available/
    sleep 1
    # Activer cette nouvelle configuration
    sudo ln -s /etc/openresty/sites-available/clients /etc/openresty/sites-enabled/

    # Création de l'interface AJAX
    sudo mkdir -p /var/www/html
    sudo ln -s /var/lib/mosquitto/clients.json /var/www/html/clients.json
    sudo ln -s /var/lib/mosquitto/monitoring.json /var/www/html/monitoring.json
    sudo ln -s /var/lib/mosquitto/map.json /var/www/html/map.json
    # Copie de index.html vers /var/www/html/
    sudo cp index.html /var/www/html/
    # Copie de setting.html vers /var/www/html/
    sudo cp setting.html /var/www/html/
    # Copie du dossier 'src-img' vers /var/www/html/
    cp -R src-img /var/www/html/
    # Copie du script update_vavoo.sh vers le path /usr/local/bin/
    sudo cp update_vavoo.sh /usr/local/bin/
    chmod +x /usr/local/bin/update_vavoo.sh
    
    # Copie du script xtream.json  vers le path /var/www/html/
    sudo cp xtream.json /var/www/html/
    # Copie du script bandwidth.json  vers le path /var/www/html/
    sudo cp bandwidth.json /var/www/html/
    # Copie du script kickoff.json  vers le path /var/www/html/
    sudo cp kickoff.json /var/www/html/
    # Copie du script acces.json  vers le path /var/www/html/
    sudo cp acces.json /var/www/html/
    # Copie du script pass.json  vers le path /etc/openresty/
    sudo cp pass.json /etc/openresty/
    
    # Copie du script domaine_script.sh vers le path /usr/local/bin/
    #sudo cp domaine_script.sh /usr/local/bin/
    #chmod +x /usr/local/bin/domaine_script.sh
    
    # Lancement du script domaine_script.sh avant openresty
    #sudo /usr/local/bin/domaine_script.sh
    
    sudo systemctl enable openresty                
    sudo systemctl start openresty
    sleep 5

    if openresty -v &> /dev/null; then
        echo_green "OpenResty installé avec succès."        
    else
        echo_red "L'installation d'OpenResty a échoué."
    fi
    
    sleep 5
}

# Fonction commune : Installation de OpenResty
function installation_openresty_client() {
    echo "Installation d'OpenResty en cours..."
    sudo apt-get -y install --no-install-recommends wget gnupg ca-certificates lsb-release
    sudo wget -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
    echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" \
     | sudo tee /etc/apt/sources.list.d/openresty.list
    sudo apt update
    sudo apt install -y openresty
    echo_green "#############################################"
    echo_green "#                                           #"
    echo_green "#       Installation OpenResty Serveur OK   #"
    echo_green "#                                           #"
    echo_green "#############################################"
    echo "Démarrage d'OpenResty en cours..."
    sleep 1
    # Copie du nginx_client.conf vers /etc/openresty/
    sudo cp nginx_client.conf /etc/openresty/nginx.conf
    # Copie du script pass.json  vers le path /etc/openresty/
    sudo cp pass.json /etc/openresty/
    sleep 2  
    # Creation fichier log
    sudo mkdir /var/log/nginx
    echo "" > /var/log/nginx/access.log
    echo "" > /var/log/nginx/error.log
    # Copier le script dell_client.sh
    sudo mkdir dell
    sudo cp dell_client.sh /dell/
    # Demarage du service
    sudo systemctl enable openresty                
    sudo systemctl start openresty
    sleep 5

    if openresty -v &> /dev/null; then
        echo_green "OpenResty Clients installé avec succès."        
    else
        echo_red "L'installation d'OpenResty Client a échoué."
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
    echo_orange "Quelle est l'IP du Serveur Broker : "
    read -p "" serveur_ip
    echo_orange "Quel est le nom d'utilisateur : "
    read -p "" utilisateur    
    echo # Nouvelle ligne pour rendre l'affichage plus propre


    sudo mosquitto_passwd -c /etc/mosquitto/passwordfile "$utilisateur"
    sudo bash -c 'grep -qxF "allow_anonymous false" /etc/mosquitto/mosquitto.conf || echo "allow_anonymous false" >> /etc/mosquitto/mosquitto.conf'
    sudo bash -c 'grep -qxF "password_file /etc/mosquitto/passwordfile" /etc/mosquitto/mosquitto.conf || echo "password_file /etc/mosquitto/passwordfile" >> /etc/mosquitto/mosquitto.conf'

    echo_orange "Quel est le mot de passe precedant [Encore SVP] : "
    read -s -p "" mot_de_passe
    
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

    echo "Démarrage de l'installation [Corps_MAP] en mode Client..."    

    # Copie du fichier corps_map.sh dans /usr/local/bin
    echo "Copie du fichier corps_map.sh vers /usr/local/bin..."
    sudo cp corps_map.sh /usr/local/bin/corps_map.sh
    
    # Remplacer les termes 'PPP', 'USPAS', et 'PASW' dans le fichier copié
    echo "Modification des variables dans le fichier /usr/local/bin/corps_map.sh..."
    sudo sed -i "s/PPP/$serveur_ip/g" /usr/local/bin/corps_map.sh
    sudo sed -i "s/USPAS/$utilisateur/g" /usr/local/bin/corps_map.sh
    sudo sed -i "s/PASW/$mot_de_passe/g" /usr/local/bin/corps_map.sh

    # Rendre le script exécutable
    sudo chmod +x /usr/local/bin/corps_map.sh

    # Copie du fichier corps_map.service dans /etc/systemd/system/
    echo "Copie du fichier corps_map.service vers /etc/systemd/system/..."
    sudo cp corps_map.service /etc/systemd/system/corps_map.service

    # Preparation des dossier [ENCPROFIL]
    mkdir /root/encprofil
    echo "Copie des fichiers BASE150 BASE200 BASE225 vers /root/encprofil/..."
    sudo cp ./base-prof/ffmpeg /root/encprofil/
    sudo cp ./base-prof/ffmpeg-op1 /root/encprofil/
    sudo cp ./base-prof/gst /root/encprofil/
    sudo cp ./base-prof/gst-op1 /root/encprofil/
    
    # Preparation des dossier [PID]
    mkdir /root/pid
    echo "Creation du fichier [pid.conf]...."
    touch /root/pid/pid.conf

    echo "Verification des creations de dossier et fichiers"
    test -d /root/encprofil && echo_green "Le dossier [encprofil] existe" || echo_red "Le dossier [encprofil] n'existe pas"
    test -d /root/pid && echo_green "Le dossier [pid] existe" || echo_red "Le dossier [pid] n'existe pas"  
    
    # Activer et démarrer le service
    echo "Activation et démarrage du service corps_map.service..."
    sudo systemctl enable corps_map.service
    sudo systemctl start corps_map.service

    echo_green "#######################################################"
    echo_green "#                                                     #"
    echo_green "#  Installation du mode Client [Corps MAP] terminée   #"
    echo_green "#                                                     #"
    echo_green "#######################################################"

    sleep 5

    echo "Démarrage de l'installation [PASS] en mode Client..."    

    # Copie du fichier mqtt_pass_listener.sh dans /usr/local/bin
    echo "Copie du fichier mqtt_pass_listener.sh vers /usr/local/bin..."
    sudo cp mqtt_pass_listener.sh /usr/local/bin/mqtt_pass_listener.sh
    
    # Remplacer les termes 'PPP', 'USPAS', et 'PASW' dans le fichier copié
    echo "Modification des variables dans le fichier /usr/local/bin/mqtt_pass_listener.sh..."
    sudo sed -i "s/PPP/$serveur_ip/g" /usr/local/bin/mqtt_pass_listener.sh
    sudo sed -i "s/USPAS/$utilisateur/g" /usr/local/bin/mqtt_pass_listener.sh
    sudo sed -i "s/PASW/$mot_de_passe/g" /usr/local/bin/mqtt_pass_listener.sh

    # Rendre le script exécutable
    sudo chmod +x /usr/local/bin/mqtt_pass_listener.sh

    # Copie du fichier mqtt_pass_listener.service dans /etc/systemd/system/
    echo "Copie du fichier mqtt_pass_listener.service vers /etc/systemd/system/..."
    sudo cp mqtt_pass_listener.service /etc/systemd/system/mqtt_pass_listener.service 
    
    # Activer et démarrer le service
    echo "Activation et démarrage du service mqtt_pass_listener.service..."
    sudo systemctl enable mqtt_pass_listener.service
    sudo systemctl start mqtt_pass_listener.service

    echo_green "#########################################################"
    echo_green "#                                                       #"
    echo_green "#  Installation du mode Client [PASS Listener] terminée #"
    echo_green "#                                                       #"
    echo_green "#########################################################"

    sleep 5
}

# Fonction spécifique : Installation en mode Serveur
function installation_serveur() {

    echo "Démarrage de l'installation [listener] en mode Serveur..."
    sleep 2

    echo "Démarrage de l'installation de la securité Brocker [AVANT...]"
    sleep 2   

    # Demander les trois questions et stocker les réponses
    echo_orange "Quelle est l'IP du Serveur Broker : "
    read -p "" serveur_ip
    echo_orange "Quel est le nom d'utilisateur : "
    read -p "" utilisateur
    echo # Nouvelle ligne pour rendre l'affichage plus propre

    sudo mosquitto_passwd -c /etc/mosquitto/passwordfile "$utilisateur"
    sudo bash -c 'grep -qxF "allow_anonymous false" /etc/mosquitto/mosquitto.conf || echo "allow_anonymous false" >> /etc/mosquitto/mosquitto.conf'
    sudo bash -c 'grep -qxF "password_file /etc/mosquitto/passwordfile" /etc/mosquitto/mosquitto.conf || echo "password_file /etc/mosquitto/passwordfile" >> /etc/mosquitto/mosquitto.conf'
    echo_orange "Quel est le mot de passe precedant [Encore SVP] : "
    read -s -p "" mot_de_passe
    
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

    # Creer le fichier cleints.json
    sudo bash -c 'echo "[]" > /var/lib/mosquitto/clients.json'

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

    # Copie du fichier mqtt_server_listener_monitoring.sh dans /usr/local/bin
    echo "Copie du fichier mqtt_server_listener_monitoring.sh vers /usr/local/bin..."
    sudo cp mqtt_server_listener_monitoring.sh /usr/local/bin/mqtt_server_listener_monitoring.sh
    
    # Remplacer les termes 'PPP', 'USPAS', et 'PASW' dans le fichier copié
    echo "Modification des variables dans le fichier /usr/local/bin/mqtt_server_listener_monitoring.sh..."
    sudo sed -i "s/PPP/$serveur_ip/g" /usr/local/bin/mqtt_server_listener_monitoring.sh
    sudo sed -i "s/USPAS/$utilisateur/g" /usr/local/bin/mqtt_server_listener_monitoring.sh
    sudo sed -i "s/PASW/$mot_de_passe/g" /usr/local/bin/mqtt_server_listener_monitoring.sh

    # Rendre le script exécutable
    sudo chmod +x /usr/local/bin/mqtt_server_listener_monitoring.sh

    # Copie du fichier mqtt_server_listener_monitoring.service dans /etc/systemd/system/
    echo "Copie du fichier mqtt_server_listener_monitoring.service vers /etc/systemd/system/..."
    sudo cp mqtt_server_listener_monitoring.service /etc/systemd/system/mqtt_server_listener_monitoring.service

    # Creer le fichier monitoring.json
    sudo bash -c 'echo "[]" > /var/lib/mosquitto/monitoring.json'

    # Activer et démarrer le service
    echo "Activation et démarrage du service mqtt_server_listener_monitoring.service..."
    sudo systemctl enable mqtt_server_listener_monitoring.service
    sudo systemctl start mqtt_server_listener_monitoring.service

    echo_green "########################################################"
    echo_green "#                                                      #"
    echo_green "#  Installation du mode Serveur [Monitoring] terminée  #"
    echo_green "#                                                      #"
    echo_green "########################################################"

    # Copie du fichier run_observeur.sh dans /usr/local/bin
    echo "Copie du fichier run_observeur.sh vers /usr/local/bin..."
    sudo cp run_observeur.sh /usr/local/bin/run_observeur.sh
    
    # Remplacer les termes 'PPP', 'USPAS', et 'PASW' dans le fichier copié
    echo "Modification des variables dans le fichier /usr/local/bin/run_observeur.sh..."
    sudo sed -i "s/PPP/$serveur_ip/g" /usr/local/bin/run_observeur.sh
    sudo sed -i "s/USPAS/$utilisateur/g" /usr/local/bin/run_observeur.sh
    sudo sed -i "s/PASW/$mot_de_passe/g" /usr/local/bin/run_observeur.sh

    # Rendre le script exécutable
    sudo chmod +x /usr/local/bin/run_observeur.sh

    # Copie du fichier run_observeur.service dans /etc/systemd/system/
    echo "Copie du fichier run_observeur.service vers /etc/systemd/system/..."
    sudo cp run_observeur.service /etc/systemd/system/run_observeur.service

    # Creer le fichier monitoring.json
    sudo bash -c 'echo "[]" > /var/lib/mosquitto/map.json'

    # Activer et démarrer le service
    echo "Activation et démarrage du service run_observeur.service..."
    sudo systemctl enable run_observeur.service
    sudo systemctl start run_observeur.service

    echo_green "###########################################################"
    echo_green "#                                                         #"
    echo_green "#  Installation du mode Serveur [Run Observeur] terminée  #"
    echo_green "#                                                         #"
    echo_green "###########################################################"

    sleep 5

       # Copie du fichier run_observeur.sh dans /usr/local/bin
    echo "Copie du fichier stream_run.sh vers /usr/local/bin..."
    sudo cp stream_run.sh /usr/local/bin/stream_run.sh   

    # Rendre le script exécutable
    sudo chmod +x /usr/local/bin/stream_run.sh

    # Copie du fichier stream_run.service dans /etc/systemd/system/
    echo "Copie du fichier stream_run.service vers /etc/systemd/system/..."
    sudo cp stream_run.service /etc/systemd/system/stream_run.service

    # Creer le fichier monitoring.json
    sudo bash -c 'echo "[]" > /var/www/html/streaming_run.json'

    # Activer et démarrer le service
    echo "Activation et démarrage du service stream_run.service..."
    sudo systemctl enable stream_run.service
    sudo systemctl start stream_run.service

    echo_green "###########################################################"
    echo_green "#                                                         #"
    echo_green "#  Installation du mode Serveur [Run Streaming] terminée  #"
    echo_green "#                                                         #"
    echo_green "###########################################################"

    sleep 5

    --

    echo "Démarrage de l'installation [TRASFERT PASS] en mode Serveur..."    

    # Copie du fichier mqtt_pass_transfert.sh dans /usr/local/bin
    echo "Copie du fichier mqtt_pass_transfert.sh vers /usr/local/bin..."
    sudo cp mqtt_pass_transfert.sh /usr/local/bin/mqtt_pass_transfert.sh
    
    # Remplacer les termes 'PPP', 'USPAS', et 'PASW' dans le fichier copié
    echo "Modification des variables dans le fichier /usr/local/bin/mqtt_pass_listener.sh..."
    sudo sed -i "s/PPP/$serveur_ip/g" /usr/local/bin/mqtt_pass_transfert.sh
    sudo sed -i "s/USPAS/$utilisateur/g" /usr/local/bin/mqtt_pass_transfert.sh
    sudo sed -i "s/PASW/$mot_de_passe/g" /usr/local/bin/mqtt_pass_transfert.sh

    # Rendre le script exécutable
    sudo chmod +x /usr/local/bin/mqtt_pass_transfert.sh

    # Copie du fichier mqtt_pass_transfert.service dans /etc/systemd/system/
    echo "Copie du fichier mqtt_pass_transfert.service vers /etc/systemd/system/..."
    sudo cp mqtt_pass_transfert.service /etc/systemd/system/mqtt_pass_transfert.service 
    
    # Activer et démarrer le service
    echo "Activation et démarrage du service mqtt_pass_listener.service..."
    sudo systemctl enable mqtt_pass_transfert.service
    sudo systemctl start mqtt_pass_transfert.service

    echo_green "#########################################################"
    echo_green "#                                                       #"
    echo_green "#  Installation du mode Client [PASS Listener] terminée #"
    echo_green "#                                                       #"
    echo_green "#########################################################"

    sleep 5
}

# Exécution des étapes en fonction du choix
case $choix in
    1)
        mise_a_jour_systeme
        installation_dependances
        firewall_client_open
        installation_gestremer
        installation_python
        installation_mosquitto
        installation_client
        installation_Docker
        installation_srs
        installation_openresty_client        
        ;;
    2)
        mise_a_jour_systeme
        installation_dependances
        firewall_serveur_open
        installation_mosquitto
        installation_serveur
        installation_Docker
        installation_openresty_server
        installation_node
        installation_kickoff
        ;;
    q)
        echo "Installation annulée. À bientôt!"
        exit 0
        ;;
    *)
        echo "Choix invalide. Veuillez exécuter à nouveau le script."
        ;;
esac
