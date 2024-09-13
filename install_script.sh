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

# Fonction pour configurer le client Mosquitto
configure_mosquitto_client() {
    read -p "Entrez l'adresse IP du broker Mosquitto : " broker_ip
    echo "Configuration du client Mosquitto avec l'adresse IP du broker : $broker_ip"

    # Créer un fichier de configuration pour le client
    sudo bash -c "cat > /etc/mosquitto/mosquitto.conf << EOF
# Configuration du client Mosquitto
connection mybroker
address $broker_ip
EOF"
}

# Fonction pour installer Mosquitto (MQTT)
install_mosquitto() {
    echo "Que souhaitez-vous installer pour Mosquitto (MQTT) ?"
    echo "1) Serveur Mosquitto"
    echo "2) Client Mosquitto"
    echo "3) Serveur et Client Mosquitto"
    read -p "Entrez le numéro de votre choix : " mosquitto_choice

    case $mosquitto_choice in
        1)
            echo "Installation du serveur Mosquitto..."
            sudo apt install -y mosquitto
            if mosquitto -v &> /dev/null; then
                echo "Serveur Mosquitto installé avec succès."
                configure_mosquitto_security
            else
                echo "L'installation du serveur Mosquitto a échoué."
            fi
            ;;

        2)
            echo "Installation du client Mosquitto..."
            sudo apt install -y mosquitto-clients
            if mosquitto_pub -h &> /dev/null; then
                echo "Client Mosquitto installé avec succès."
                configure_mosquitto_client
            else
                echo "L'installation du client Mosquitto a échoué."
            fi
            ;;

        3)
            echo "Installation du serveur et client Mosquitto..."
            sudo apt install -y mosquitto mosquitto-clients
            if mosquitto -v &> /dev/null && mosquitto_pub -h &> /dev/null; then
                echo "Serveur et Client Mosquitto installés avec succès."
                configure_mosquitto_security
                configure_mosquitto_client
            else
                echo "L'installation du serveur ou du client Mosquitto a échoué."
            fi
            ;;

        *)
            echo "Choix invalide. Veuillez relancer et sélectionner un numéro valide."
            ;;
    esac
}

# Fonction pour installer curl
install_curl() {
    echo "Installation de curl..."
    sudo apt install -y curl
}

# Fonction pour installer git
install_git() {
    echo "Installation de git..."
    sudo apt install -y git
}

# Fonction pour installer Docker
install_docker() {
    echo "Installation de Docker..."
    
    # Désinstallation des anciennes versions
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
    if sudo docker run hello-world; then
        echo "Docker a été installé avec succès."
    else
        echo "L'installation de Docker a échoué."
    fi
}

# Fonction pour installer et configurer SRS
install_srs() {
    if command -v docker &> /dev/null; then
        echo "Installation de SRS via Docker..."
        
        # Créer un script de démarrage pour SRS
        echo "Création d'un script de démarrage pour SRS..."
        sudo bash -c 'cat > /usr/local/bin/start-srs.sh << EOF
#!/bin/bash
docker run --rm -d --name srs -p 1935:1935 -p 1985:1985 -p 8080:8080 ossrs/srs:latest
EOF'
        sudo chmod +x /usr/local/bin/start-srs.sh

        echo "Démarrage de SRS..."
        sudo /usr/local/bin/start-srs.sh

        # Vérifier que SRS fonctionne
        if curl -s http://localhost:8080 | grep -q "SRS"; then
            echo "SRS fonctionne correctement."
        else
            echo "SRS ne fonctionne pas correctement."
        fi
    else
        echo "Docker n'est pas installé. Veuillez installer Docker d'abord."
    fi
}

# Fonction pour installer et configurer nginx
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

# Affichage du menu
echo "Sélectionnez l'option souhaitée :"
echo "1) Vérifier l'installation"
echo "2) Installer les outils de compilation"
echo "3) Installer unzip"
echo "4) Installer automake"
echo "5) Installer tclsh"
echo "6) Installer cmake"
echo "7) Installer pkg-config"
echo "8) Installer nginx"
echo "9) Installer Mosquitto (MQTT)"
echo "10) Installer curl"
echo "11) Installer git"
echo "12) Installer Docker"
echo "13) Installer SRS"
echo "14) Quitter"
read -p "Entrez le numéro de votre choix : " choice

case $choice in
    1)
        echo "Vérification des installations..."
        check_installed mosquitto
        check_installed curl
        check_installed git
        check_installed docker
        ;;
    2)
        install_build_essentials
        ;;
    3)
        install_unzip
        ;;
    4)
        install_automake
        ;;
    5)
        install_tclsh
        ;;
    6)
        install_cmake
        ;;
    7)
        install_pkg_config
        ;;
    8)
        install_nginx
        ;;
    9)
        install_mosquitto
        ;;
    10)
        install_curl
        ;;
    11)
        install_git
        ;;
    12)
        install_docker
        ;;
    13)
        install_srs
        ;;
    14)
        echo "Quitter..."
        exit 0
        ;;
    *)
        echo "Choix invalide. Veuillez relancer le script et sélectionner un numéro valide."
        ;;
esac
