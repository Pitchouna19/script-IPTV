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

# Fonction pour installer les outils de compilation
install_build_essentials() {
    echo "Installation des outils de compilation (gcc, make, etc.)..."
    sudo apt install -y build-essential
}

# Fonction pour installer unzip
install_unzip() {
    echo "Installation de unzip..."
    sudo apt install -y unzip
}

# Fonction pour installer automake
install_automake() {
    echo "Installation de automake..."
    sudo apt install -y automake
}

# Fonction pour installer tclsh
install_tclsh() {
    echo "Installation de tclsh..."
    sudo apt install -y tclsh
}

# Fonction pour installer cmake
install_cmake() {
    echo "Installation de cmake..."
    sudo apt install -y cmake
}

# Fonction pour installer pkg-config
install_pkg_config() {
    echo "Installation de pkg-config..."
    sudo apt install -y pkg-config
}

# Fonction pour installer nginx
install_nginx() {
    echo "Installation de nginx..."
    sudo apt install -y nginx
    if nginx -v &> /dev/null; then
        echo "nginx installé avec succès."
        echo "Activation de nginx au démarrage..."
        sudo systemctl enable nginx
        echo "Démarrage de nginx..."
        sudo systemctl start nginx
    else
        echo "L'installation de nginx a échoué."
    fi
}

# Fonction pour configurer le serveur Mosquitto avec utilisateur et mot de passe
configure_mosquitto_security() {
    # Récupérer le nom de l'ordinateur
    local hostname=$(hostname)
    
    echo "Configuration de la sécurité pour Mosquitto..."
    sudo bash -c 'cat > /etc/mosquitto/conf.d/default.conf << EOF
allow_anonymous false
password_file /etc/mosquitto/passwd
EOF'

    sudo touch /etc/mosquitto/passwd
    
    # Utiliser le nom de l'ordinateur dans la commande mosquitto_passwd
    sudo mosquitto_passwd -b /etc/mosquitto/passwd $hostname 19041980

    echo "Redémarrage du service Mosquitto pour appliquer les modifications..."
    sudo systemctl restart mosquitto
}

# Fonction pour configurer un topic spécifique
configure_mosquitto_topic() {
    echo "Configuration du topic 'serveur/link'..."
    mosquitto_pub -t "serveur/link" -m "Configuration du topic 'serveur/link'"
}

# Fonction pour installer Mosquitto (MQTT)
install_mosquitto() {
    echo "Que souhaitez-vous installer pour Mosquitto (MQTT) ?"
    echo "1) Serveur Mosquitto"
    echo "2) Client Mosquitto"
    read -p "Entrez le numéro de votre choix : " mosquitto_choice

    case $mosquitto_choice in
        1)
            echo "Installation du serveur Mosquitto..."
            sudo apt install -y mosquitto
            if mosquitto -v &> /dev/null; then
                echo "Serveur Mosquitto installé avec succès."
                configure_mosquitto_security
                configure_mosquitto_topic
            else
                echo "L'installation du serveur Mosquitto a échoué."
            fi
            ;;
        2)
            echo "Installation du client Mosquitto..."
            sudo apt install -y mosquitto-clients
            if mosquitto_sub -h &> /dev/null; then
                echo "Client Mosquitto installé avec succès."
                read -p "Entrez l'adresse IP du broker : " broker_ip
                read -p "Entrez le nom d'utilisateur : " username
                read -sp "Entrez le mot de passe : " password
                echo

                # Création de la configuration pour le client
                echo "Adresse IP du broker : $broker_ip"
                echo "Nom d'utilisateur : $username"
                echo "Mot de passe : $password"

                echo "Configuration du client Mosquitto..."
                sudo bash -c "cat > /etc/mosquitto/mosquitto.conf << EOF
connection mybroker
address $broker_ip
username $username
password $password
EOF"
                
                # Création du script de surveillance
                sudo bash -c 'cat > /usr/local/bin/monitor.sh << EOF
#!/bin/bash

# Configuration
BROKER_IP="'"$broker_ip"'"
TOPIC="monitoring/data"
USERNAME="'"$username"'"
PASSWORD="'"$password"'"

get_cpu_usage() {
    mpstat -P ALL 1 1 | awk "/Average:/ && \$3 ~ /[0-9.]/ { print \$3 }"
}

get_network_usage() {
    iface=\$(ip -o -4 route show to default | awk "{print \$5}")
    rx_bytes=\$(cat /sys/class/net/\$iface/statistics/rx_bytes)
    tx_bytes=\$(cat /sys/class/net/\$iface/statistics/tx_bytes)
    echo "{\"rx_bytes\": \$rx_bytes, \"tx_bytes\": \$tx_bytes}"
}

publish_metrics() {
    while true; do
        cpu_usage=\$(get_cpu_usage)
        network_usage=\$(get_network_usage)
        json_data=\$(printf "{\"cpu_usage\": %s, \"network_usage\": %s}" "\$cpu_usage" "\$network_usage")
        mosquitto_pub -h "\$BROKER_IP" -t "\$TOPIC" -u "\$USERNAME" -P "\$PASSWORD" -m "\$json_data"
        sleep 10
    done
}

publish_metrics
EOF'

                sudo chmod +x /usr/local/bin/monitor.sh

                # Création du fichier de service systemd
                sudo bash -c 'cat > /etc/systemd/system/mqtt-monitor.service << EOF
[Unit]
Description=MQTT Monitoring Service
After=network.target

[Service]
ExecStart=/usr/local/bin/monitor.sh
Restart=always
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF'

                # Activer et démarrer le service
                sudo systemctl daemon-reload
                sudo systemctl enable mqtt-monitor
                sudo systemctl start mqtt-monitor

                echo "Le client Mosquitto est installé et configuré pour surveiller le CPU et le réseau."
            else
                echo "L'installation du client Mosquitto a échoué."
            fi
            ;;
        *)
            echo "Choix invalide pour Mosquitto."
            ;;
    esac
}

# Fonction pour installer Docker et SRS
install_docker() {
    echo "Installation de Docker..."
    sudo apt install -y docker.io
    if docker --version &> /dev/null; then
        echo "Docker installé avec succès."
    else
        echo "L'installation de Docker a échoué."
    fi
}

install_srs() {
    echo "Installation de SRS avec Docker..."
    if docker --version &> /dev/null; then
        sudo docker pull ossrs/srs
        sudo bash -c 'cat > /etc/systemd/system/srs-docker.service << EOF
[Unit]
Description=SRS Docker Service
After=network.target

[Service]
ExecStart=/usr/bin/docker run --rm -p 1935:1935 -p 1985:1985 ossrs/srs
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

        sudo systemctl daemon-reload
        sudo systemctl enable srs-docker
        sudo systemctl start srs-docker

        echo "SRS installé et configuré avec Docker."
    else
        echo "Docker n'est pas installé. Veuillez installer Docker d'abord."
    fi
}

# Fonction pour installer toutes les dépendances
install_all_dependencies() {
    install_build_essentials
    install_unzip
    install_automake
    install_tclsh
    install_cmake
    install_pkg_config
    install_nginx
    install_mosquitto
    install_docker
    install_srs
}

# Fonction principale pour afficher le menu et exécuter les actions
main_menu() {
    echo "Sélectionnez une option :"
    echo "1) Vérifier les dépendances"
    echo "2) Installer les dépendances"
    echo "3) Installer toutes les dépendances"
    echo "4) Quitter"
    read -p "Entrez le numéro de votre choix : " choice

    case $choice in
        1)
            echo "Vérification des dépendances..."
            check_installed "mosquitto"
            check_installed "build-essential"
            check_installed "unzip"
            check_installed "automake"
            check_installed "tclsh"
            check_installed "cmake"
            check_installed "pkg-config"
            check_installed "nginx"
            ;;
        2)
            echo "Installation des dépendances..."
            install_build_essentials
            install_unzip
            install_automake
            install_tclsh
            install_cmake
            install_pkg_config
            install_nginx
            install_mosquitto
            install_docker
            install_srs
            ;;
        3)
            echo "Installation de toutes les dépendances..."
            install_all_dependencies
            ;;
        4)
            echo "Quitter"
            exit 0
            ;;
        *)
            echo "Choix invalide."
            ;;
    esac
}

# Exécuter le menu principal
main_menu
