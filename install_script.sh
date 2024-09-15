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
    for tool in unzip automake tclsh cmake pkg-config curl git jq sysstat bc; do
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

install_nginx() {
    echo "Que souhaitez-vous installer pour Nginx ?"
    echo "1) Installation de Nginx pour Client"
    echo "2) Installation de Nginx pour Serveur (avec interface AJAX)"
    read -p "Entrez le numéro de votre choix : " nginx_choice

    case $nginx_choice in
        1)
            echo "Installation de Nginx pour Client..."
            sudo apt install -y nginx
            if nginx -v &> /dev/null; then
                echo "Nginx installé avec succès."
                echo "Activation de Nginx au démarrage..."
                sudo systemctl enable nginx
                echo "Démarrage de Nginx..."
                sudo systemctl start nginx
            else
                echo "L'installation de Nginx a échoué."
            fi
            ;;
        
        2)
            echo "Installation de Nginx pour Serveur avec interface AJAX..."
            sudo apt install -y nginx
            if nginx -v &> /dev/null; then
                echo "Nginx installé avec succès."
                echo "Activation de Nginx au démarrage..."
                sudo systemctl enable nginx
                echo "Démarrage de Nginx..."
                sudo systemctl start nginx

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

                # Activer cette nouvelle configuration
                sudo ln -s /etc/nginx/sites-available/clients /etc/nginx/sites-enabled/
                sudo systemctl restart nginx

                # Création de l'interface AJAX
                sudo mkdir -p /var/www/html
                sudo bash -c "cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html lang='fr'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Clients MQTT</title>
    <script>
        function loadClientData() {
            var xhttp = new XMLHttpRequest();
            xhttp.onreadystatechange = function() {
                if (this.readyState == 4 && this.status == 200) {
                    var clients = JSON.parse(this.responseText);
                    var output = '<h2>Liste des Clients MQTT</h2><ul>';
                    clients.forEach(function(client) {
                        output += '<li>IP: ' + client.ip + ', Charge CPU: ' + client.cpu_load + '%, Trafic IN: ' + client.network_in + ', Trafic OUT: ' + client.network_out + '</li>';
                    });
                    output += '</ul>';
                    document.getElementById('clientData').innerHTML = output;
                }
            };
            xhttp.open('GET', '/clients.json', true);
            xhttp.send();
        }

        setInterval(loadClientData, 5000); // Actualisation toutes les 5 secondes
    </script>
</head>
<body onload='loadClientData()'>
    <div id='clientData'>
        <p>Chargement des données...</p>
    </div>
</body>
</html>
EOF"

                echo "L'interface AJAX est disponible sur http://localhost:9090"
            else
                echo "L'installation de Nginx a échoué."
            fi
            ;;
        
        *)
            echo "Choix invalide. Veuillez relancer et sélectionner un numéro valide."
            ;;
    esac
    read -p "Appuyez sur [Enter] pour continuer..."
}



install_mosquitto() {
    echo "Que souhaitez-vous installer pour Mosquitto (MQTT) ?"
    echo "1) Serveur Mosquitto (inclut le client et le service d'écoute)"
    echo "2) Client Mosquitto uniquement"
    read -p "Entrez le numéro de votre choix : " mosquitto_choice

    case $mosquitto_choice in
        1)
            echo "Installation du serveur et du client Mosquitto..."
            sudo apt install -y mosquitto mosquitto-clients
            sudo systemctl start mosquitto
            sudo systemctl enable mosquitto

            if [ "$(sudo systemctl is-active mosquitto)" = "active" ]; then
                echo "Serveur Mosquitto installé et actif."
                echo "Client Mosquitto installé avec succès."
                read -p "Entrez le nom d'utilisateur pour Mosquitto : " mqtt_user
                sudo mosquitto_passwd -c /etc/mosquitto/passwordfile "$mqtt_user"

                sudo bash -c 'echo "
allow_anonymous false
password_file /etc/mosquitto/passwordfile
" >> /etc/mosquitto/mosquitto.conf'
                sudo systemctl restart mosquitto
                echo "Configuration de la sécurité terminée."

               # Demander les informations pour le script d'écoute
read -p "Entrez l'IP du broker Mosquitto : " broker_ip
read -p "Entrez le nom d'utilisateur MQTT pour le script : " mqtt_user_script
read -s -p "Entrez le mot de passe MQTT pour le script : " mqtt_pass_script
echo

# Création du script pour écouter sur le topic /client/info
cat << EOF | sudo tee /usr/local/bin/mqtt_server_listener.sh > /dev/null
#!/bin/bash
# Script pour écouter sur le topic /client/info et maintenir un tableau JSON unique basé sur l'IP
TOPIC="/client/info"
JSON_FILE="/var/lib/mosquitto/clients.json"
BROKER_IP="$broker_ip"
MQTT_USER="$mqtt_user_script"
MQTT_PASS="$mqtt_pass_script"

# Initialiser le fichier JSON vide s'il n'existe pas ou le vider au démarrage
sudo bash -c "echo '[]' > \$JSON_FILE"
sudo chmod 666 \$JSON_FILE  # S'assurer que le fichier est accessible en écriture

# Fonction pour mettre à jour ou ajouter un client dans le tableau JSON
update_or_add_client() {
    local message=\$1
    local ip=\$(echo "\$message" | jq -r '.ip')

    # Charger le fichier JSON actuel
    local current_data=\$(cat "\$JSON_FILE")

    # Vérifier si l'IP existe déjà dans le tableau
    if echo "\$current_data" | jq -e ".[] | select(.ip == \"\$ip\")" > /dev/null; then
        # Si l'IP existe, mettre à jour les valeurs correspondantes
        current_data=\$(echo "\$current_data" | jq "map(if .ip == \"\$ip\" then \$message else . end)")
    else
        # Si l'IP n'existe pas, ajouter une nouvelle entrée
        current_data=\$(echo "\$current_data" | jq ". += [\$message]")
    fi

    # Sauvegarder le nouveau contenu dans le fichier JSON
    echo "\$current_data" > "\$JSON_FILE"
}

# Écouter les messages sur le topic et traiter chaque message
mosquitto_sub -h "\$BROKER_IP" -u "\$MQTT_USER" -P "\$MQTT_PASS" -t "\$TOPIC" | while read -r message
do
    # Afficher le message reçu pour déboguer
    echo "Message reçu : \$message"

    # Mettre à jour ou ajouter le client dans le tableau JSON
    update_or_add_client "\$message"
done
EOF

# Rendre le script exécutable
sudo chmod +x /usr/local/bin/mqtt_server_listener.sh

echo "Le fichier a été créé avec succès."


                # Rendre le script exécutable
                sudo chmod +x /usr/local/bin/mqtt_server_listener.sh

                # Création du service systemd pour démarrer le script au démarrage
                sudo bash -c "cat > /etc/systemd/system/mqtt_server_listener.service << EOF
[Unit]
Description=Service pour écouter sur le topic /client/info et mettre à jour un fichier JSON avec les informations des clients
After=mosquitto.service

[Service]
ExecStart=/usr/local/bin/mqtt_server_listener.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

                # Activer et démarrer le service
                sudo systemctl enable mqtt_server_listener.service
                sudo systemctl start mqtt_server_listener.service

                echo "Le service d'écoute MQTT a été configuré et démarré pour enregistrer les informations des clients."
            else
                echo "Erreur : Mosquitto n'est pas actif."
            fi
            ;;

        2)
            echo "Installation du client Mosquitto..."
            sudo apt install -y mosquitto-clients

            # Vérification de l'installation du client Mosquitto
            if apt list --installed 2>/dev/null | grep -q "^mosquitto-clients/"; then
                echo "mosquitto-clients est installé avec succès."

                # Demande des informations de configuration
read -p "Entrez l'IP du broker Mosquitto : " broker_ip
read -p "Entrez le nom d'utilisateur MQTT : " mqtt_user
read -s -p "Entrez le mot de passe MQTT : " mqtt_pass
echo

# Création du script client pour envoyer les données au broker
cat << EOF | sudo tee /usr/local/bin/client_report.sh > /dev/null
#!/bin/bash
# Script pour envoyer les informations du client au broker MQTT

BROKER_IP="$broker_ip"
MQTT_USER="$mqtt_user"
MQTT_PASS="$mqtt_pass"
TOPIC="/client/info"

while true; do
    # Récupérer l'IP locale
    IP_CLIENT=\$(hostname -I | awk '{print \$1}')

    # Récupérer la charge CPU par cœur
    #CPU_LOAD=\$(awk -v INTERVAL=1 '{cpu_now=($2+$4); total_now=($2+$4+$5)} {if (NR>1) {cpu_diff=cpu_now-prev_cpu; total_diff=total_now-prev_total; usage=(cpu_diff*100)/total_diff; print usage "%"}; prev_cpu=cpu_now; prev_total=total_now; fflush(); system("sleep " INTERVAL);}' <(grep 'cpu ' /proc/stat))
    
    CPU_LOAD=\$(mpstat 1 1 | awk '/all/ && NR==4 {print 100 - \$12}')
    
    # Récupérer le trafic réseau (octets reçus et envoyés)
    INTERFACE=eth0  # Remplacez par votre interface réseau (ex : eth0, wlan0, etc.)
    RX_BYTES_BEFORE=\$(cat /sys/class/net/\$INTERFACE/statistics/rx_bytes)
    TX_BYTES_BEFORE=\$(cat /sys/class/net/\$INTERFACE/statistics/tx_bytes)
    
    sleep 1
    
    RX_BYTES_AFTER=\$(cat /sys/class/net/\$INTERFACE/statistics/rx_bytes)
    TX_BYTES_AFTER=\$(cat /sys/class/net/\$INTERFACE/statistics/tx_bytes)

    RX_BYTES=\$( echo "scale=2; ("\$RX_BYTES_AFTER - \$RX_BYTES_BEFORE") / 1024" | bc )
    TX_BYTES=\$( echo "scale=2; ("\$TX_BYTES_AFTER - \$TX_BYTES_BEFORE") / 1024" | bc )
    
    #RX_BYTES=\$(cat /sys/class/net/\$INTERFACE/statistics/rx_bytes)
    #TX_BYTES=\$(cat /sys/class/net/\$INTERFACE/statistics/tx_bytes)

    # Construire le message JSON
    MESSAGE=\$(printf '{\"ip\": \"%s\", \"cpu_load\": \"%s\", \"network_in\": \"%s\", \"network_out\": \"%s\"}' \
        "\$IP_CLIENT" "\$CPU_LOAD" "\$RX_BYTES" "\$TX_BYTES")

    # Publier les informations sur le topic MQTT
    mosquitto_pub -h "\$BROKER_IP" -u "\$MQTT_USER" -P "\$MQTT_PASS" -t "\$TOPIC" -m "\$MESSAGE"

    # Afficher un message de succès
    if [ \$? -eq 0 ]; then
        echo "Informations envoyées avec succès au broker MQTT."
    else
        echo "Erreur lors de l'envoi des informations au broker MQTT."
    fi

    # Attendre 10 secondes avant de répéter
    sleep 4
done
EOF

                # Rendre le script exécutable
                sudo chmod +x /usr/local/bin/client_report.sh

                # Création du service systemd pour démarrer le script au démarrage
                sudo bash -c "cat > /etc/systemd/system/client_mqtt.service << EOF
[Unit]
Description=Service pour envoyer des informations système au broker MQTT
After=network.target

[Service]
ExecStart=/usr/local/bin/client_report.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

                # Activer et démarrer le service
                sudo systemctl enable client_mqtt.service
                sudo systemctl start client_mqtt.service

                echo "Le service MQTT client a été configuré et démarré pour envoyer des informations au broker."
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
    echo "6) Installer Nginx (client/Serveur)"
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
        6)
            install_nginx
            ;;
        *)
            echo "Option invalide. Veuillez choisir une option entre 1 et 5."
            ;;
    esac
done
