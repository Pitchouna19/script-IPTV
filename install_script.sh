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

# Fonction pour installer les outils nécessaires
install_tools() {
    echo "Installation des outils nécessaires..."
    sudo apt update

    # Installer les outils nécessaires
    for tool in unzip automake tclsh cmake pkg-config nginx curl git; do
        echo "Installation de $tool..."
        sudo apt install -y $tool
        echo -e "$tool : $(check_installed $tool)"
    done
    read -p "Appuyez sur [Enter] pour continuer..."
}

# Fonction pour installer les outils de compilation
install_build_essentials() {
    echo "Installation des outils de compilation (gcc, make, etc.)..."
    sudo apt install -y build-essential
    read -p "Appuyez sur [Enter] pour continuer..."
}

# Fonction pour installer unzip
install_unzip() {
    echo "Installation de unzip..."
    sudo apt install -y unzip
    read -p "Appuyez sur [Enter] pour continuer..."
}

# Fonction pour installer automake
install_automake() {
    echo "Installation de automake..."
    sudo apt install -y automake
    read -p "Appuyez sur [Enter] pour continuer..."
}

# Fonction pour installer tclsh
install_tclsh() {
    echo "Installation de tclsh..."
    sudo apt install -y tclsh
    read -p "Appuyez sur [Enter] pour continuer..."
}

# Fonction pour installer cmake
install_cmake() {
    echo "Installation de cmake..."
    sudo apt install -y cmake
    read -p "Appuyez sur [Enter] pour continuer..."
}

# Fonction pour installer pkg-config
install_pkg_config() {
    echo "Installation de pkg-config..."
    sudo apt install -y pkg-config
    read -p "Appuyez sur [Enter] pour continuer..."
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
    read -p "Appuyez sur [Enter] pour continuer..."
}

# Fonction pour configurer la sécurité de Mosquitto
configure_mosquitto_security() {
    echo "Configuration de la sécurité de Mosquitto..."

    # Créer le fichier de mot de passe s'il n'existe pas
    if [ ! -f /etc/mosquitto/passwd ]; then
        sudo mkdir -p /etc/mosquitto
        sudo touch /etc/mosquitto/passwd
        sudo chmod 600 /etc/mosquitto/passwd
    fi

    # Ajouter un utilisateur avec un mot de passe
    read -p "Entrez le nom d'utilisateur pour Mosquitto : " mqtt_user
    read -sp "Entrez le mot de passe pour l'utilisateur $mqtt_user : " mqtt_pass
    echo
    sudo mosquitto_passwd -b /etc/mosquitto/passwd "$mqtt_user" "$mqtt_pass"

    # Vérifiez si le mot de passe a été ajouté correctement
    if [ $? -ne 0 ]; then
        echo "Erreur lors de l'ajout du mot de passe."
        return 1
    fi

    # Créer ou modifier la configuration de Mosquitto pour utiliser le fichier de mot de passe
    sudo bash -c 'cat > /etc/mosquitto/conf.d/default.conf << EOF
allow_anonymous false
password_file /etc/mosquitto/passwd
EOF'

    # Vérifiez si le fichier de configuration a été créé correctement
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la création du fichier de configuration."
        return 1
    fi

    # Redémarrer le service Mosquitto pour appliquer les changements
    sudo systemctl restart mosquitto

    echo "Sécurité de Mosquitto configurée avec succès."
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
            else
                echo "L'installation du serveur Mosquitto a échoué."
            fi
            ;;

        2)
            echo "Installation du client Mosquitto..."
            sudo apt install -y mosquitto-clients
            if mosquitto_sub -h localhost &> /dev/null; then
                echo "Client Mosquitto installé avec succès."

                # Demander l'IP du broker pour configurer le client
                read -p "Entrez l'adresse IP du broker Mosquitto : " broker_ip
                sudo bash -c "cat > /etc/mosquitto/conf.d/client.conf << EOF
connection local
address $broker_ip
username $mqtt_user
password /etc/mosquitto/passwd
EOF"

            else
                echo "L'installation du client Mosquitto a échoué."
            fi
            ;;

        *)
            echo "Choix invalide. Veuillez relancer et sélectionner un numéro valide."
            ;;
    esac
    read -p "Appuyez sur [Enter] pour continuer..."
}



# Fonction pour installer curl
install_curl() {
    echo "Installation de curl..."
    sudo apt install -y curl
    read -p "Appuyez sur [Enter] pour continuer..."
}

# Fonction pour installer git
install_git() {
    echo "Installation de git..."
    sudo apt install -y git
    read -p "Appuyez sur [Enter] pour continuer..."
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
    read -p "Appuyez sur [Enter] pour continuer..."
}

# Fonction pour installer et configurer SRS
install_srs() {
    if command -v docker &> /dev/null; then
        echo "Installation de SRS via Docker..."
        
        # Créer un script de démarrage pour SRS
        echo "Création d'un script de démarrage pour SRS..."
        sudo bash -c 'cat > /usr/local/bin/start-srs.sh << EOF
#!/bin/bash
docker run --rm -d --name srs -p 1935:1935 -p 1985:1985 -p 8080:8080 -v /usr/local/etc/srs:/usr/local/etc/srs ossrs/srs
EOF'
        
        # Rendre le script exécutable
        sudo chmod +x /usr/local/bin/start-srs.sh

        # Créer un fichier de service systemd pour SRS
        echo "Création d'un fichier de service systemd pour SRS..."
        sudo bash -c 'cat > /etc/systemd/system/srs.service << EOF
[Unit]
Description=SRS Media Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/start-srs.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF'

        # Recharger les configurations de systemd
        echo "Rechargement des configurations de systemd..."
        sudo systemctl daemon-reload

        # Démarrer le service SRS
        echo "Démarrage du service SRS..."
        sudo systemctl start srs

        # Activer le service pour qu'il démarre au démarrage
        echo "Activation du service SRS pour démarrer au démarrage..."
        sudo systemctl enable srs

        echo "SRS est maintenant en cours d'exécution et sera démarré automatiquement au prochain redémarrage."
    else
        echo -e "${RED}Docker doit être installé pour exécuter cette opération.${NC}"
    fi
    read -p "Appuyez sur [Enter] pour continuer..."
}

# Fonction pour afficher le menu
show_menu() {
    clear
    echo "======================================="
    echo "               MENU PRINCIPAL          "
    echo "======================================="
    echo "1) les outils nécessaires"
    echo "2) Installer et configurer Mosquitto (MQTT)"
    echo "3) Installer Docker"
    echo "4) Installer SRS (Simple Real-time Server)"
    echo "5) Quitter"
    echo "======================================="
    read -p "Choisissez une option [1-5] : " choice
}

# Boucle principale du script
while true; do
    show_menu
    case $choice in
        1)
            clear
            echo "Que souhaitez-vous faire ?"
            echo "1) Installer tous les outils nécessaires"
            echo "2) Vérifier les outils nécessaires"
            read -p "Entrez le numéro de votre choix : " tool_choice

            case $tool_choice in
                1)
                    install_tools
                    ;;
                2)
                    echo "Vérification des outils nécessaires..."
                    echo -e "1) unzip : $(check_installed unzip)"
                    echo -e "2) automake : $(check_installed automake)"
                    echo -e "3) tclsh : $(check_installed tclsh)"
                    echo -e "4) cmake : $(check_installed cmake)"
                    echo -e "5) pkg-config : $(check_installed pkg-config)"
                    echo -e "6) nginx : $(check_installed nginx)"
                    echo -e "7) curl : $(check_installed curl)"
                    echo -e "8) git : $(check_installed git)"
                    read -p "Appuyez sur [Enter] pour continuer..."
                    ;;
                *)
                    echo "Choix invalide. Veuillez relancer et sélectionner un numéro valide."
                    ;;
            esac
            ;;
        2)
            install_mosquitto
            ;;
        3)
            install_docker
            ;;
        4)
            install_srs
            ;;
        5)
            echo "Quitter le script."
            exit 0
            ;;
        *)
            echo "Option invalide. Veuillez choisir une option entre 1 et 5."
            ;;
    esac
done
