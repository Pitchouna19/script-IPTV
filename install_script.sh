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

# Fonction pour vérifier et afficher le statut des outils nécessaires
check_tools_status() {
    echo "Statut des outils nécessaires :"
    
    tools=("unzip" "automake" "tclsh" "cmake" "pkg-config" "nginx" "curl" "git")
    
    for tool in "${tools[@]}"; do
        if command -v $tool &> /dev/null; then
            echo -e "${GREEN}$tool : INSTALLÉ${NC}"
        else
            echo -e "${RED}$tool : NON INSTALLÉ${NC}"
        fi
    done

    # Pause pour permettre à l'utilisateur de voir le résultat avant de revenir au menu
    read -p "Appuyez sur Entrée pour revenir au menu..." </dev/tty
}

# Fonction pour installer les outils nécessaires
install_tools() {
    echo "Installation des outils nécessaires..."
    
    sudo apt install -y unzip automake tclsh cmake pkg-config nginx curl git
    
    # Vérification de l'installation
    check_tools_status
}

# Fonction pour installer les outils de compilation
install_build_essentials() {
    echo "Installation des outils de compilation (gcc, make, etc.)..."
    sudo apt install -y build-essential || echo -e "${RED}Échec de l'installation des outils de compilation.${NC}"

    # Pause pour permettre à l'utilisateur de voir le résultat avant de revenir au menu
    read -p "Appuyez sur Entrée pour revenir au menu..." </dev/tty
}

# Fonction pour installer Docker
install_docker() {
    echo "Installation de Docker..."
    
    # Désinstallation des anciennes versions
    echo "Désinstallation des anciennes versions de Docker..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        sudo apt-get remove -y $pkg
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
        echo -e "${RED}L'installation de Docker a échoué.${NC}"
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
docker run --rm -d --name srs -p 1935:1935 -p 1985:1985 -p 8080:8080 -v /usr/local/etc/srs:/usr/local/etc/srs ossrs/srs
EOF'

        # Rendre le script exécutable
        sudo chmod +x /usr/local/bin/start-srs.sh

        # Créer le fichier de service systemd
        echo "Création du service systemd pour SRS..."
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
}


# Fonction pour afficher le menu principal
show_menu() {
    clear
    echo "Sélectionnez une option :"
    echo "1) Vérifier le statut des outils nécessaires"
    echo "2) Installer les outils nécessaires"
    echo "3) Installer les outils de compilation"
    echo "4) Installer Docker"
    echo "5) Installer et configurer SRS"
    echo "6) Quitter"
}

# Boucle principale
while true; do
    show_menu
    read -p "Entrez votre choix [1-6] : " choice

    case $choice in
        1) check_tools_status ;;
        2) install_tools ;;
        3) install_build_essentials ;;
        4) install_docker ;;
        5) install_srs ;;
        6) exit 0 ;;
        *) echo "Choix invalide. Veuillez entrer un nombre entre 1 et 6." ;;
    esac
done
