#!/bin/bash

#!/bin/bash
# Script pour écouter sur le topic /client/info et maintenir un tableau JSON unique basé sur l'IP
BROKER_IP="PPP"
MQTT_USER="USPAS"
MQTT_PASS="PASW"
TOPIC="/client/infomap"


# Déclaration d'un tableau associatif pour stocker les PIDs
declare -A ffmpeg_pids
declare -A ffmpeg_prof

file="/root/pid/pid.conf"

# Fonction pour lancer ffmpeg avec une URL d'entrée
start_ffmpeg() {
    local type_id="$1"
    local stream_id="$2"  # Prendre l'ID du flux comme argument
    local profil_id="$3"  # Prendre l'ID du profil comme argument

    # Chemin du fichier profil contenant la commande ffmpeg
    local profil_file="/root/encprofil/$profil_id"

    # Vérifier si le fichier profil existe
    if [[ -f "$profil_file" ]]; then
        echo "Lancement de ffmpeg avec le profil : $profil_id pour le flux : $stream_id"

        # Lire la commande à partir du fichier de profil
        cmd=$(sed -e "s#\$1#$stream_id#g" -e "s#\$2#$type_id#g" "$profil_file")

        # Exécuter la commande et récupérer directement le PID de ffmpeg
        eval "$cmd" &

        last_segment=$(basename "$stream_id")
        
        # Donnons à 'ffmpeg' le temps de se lancer, et récupérons le bon PID
        ffmpeg_pid=$(pgrep -n -f "ffmpeg.*$last_segment")
        
        # Vérifier si on a bien récupéré un PID
        if [[ -n "$ffmpeg_pid" ]]; then
            ffmpeg_pids["$last_segment"]="$ffmpeg_pid"  # Enregistrer le PID dans le tableau associatif
            ffmpeg_prof["$last_segment"]="$profil_id"  # Enregistrer le Profil dans le tableau associatif

            echo "Processus ffmpeg lancé pour le flux $stream_id avec PID : $ffmpeg_pid"
        else
            echo "Erreur : Impossible de récupérer le PID du processus ffmpeg pour le flux $stream_id."
        fi
    else
        echo "Erreur : le fichier profil $profil_file n'existe pas."
    fi
}


# Fonction pour arrêter ffmpeg pour un stream_id donné
stop_ffmpeg() {
    local stream_id="$1"

    last_segment=$(basename "$stream_id")

    if [[ -n "${ffmpeg_pids[$last_segment]}" && -e /proc/${ffmpeg_pids[$last_segment]} ]]; then
        echo "Arrêt du processus ffmpeg pour le flux $stream_id avec PID : ${ffmpeg_pids[$last_segment]}"
        
        # Tenter d'arrêter le processus en douceur
        kill "${ffmpeg_pids[$last_segment]}"
        sleep 2  # Attendre un peu pour que le processus se termine

        # Vérifier si le processus est toujours en cours
        if kill -0 "${ffmpeg_pids[$last_segment]}" 2>/dev/null; then
            echo "Le processus ne s'est pas arrêté, forçage de l'arrêt avec SIGKILL..."
            kill -9 "${ffmpeg_pids[$last_segment]}"  # Forcer l'arrêt avec SIGKILL
        fi
        
        # Supprimer le PID du tableau associatif
        unset ffmpeg_pids["$last_segment"]
        # Supprimer le PROFIL du tableau associatif
        unset ffmpeg_prof["$last_segment"]
        
        # Supprimer le 'stream_id' du fichier
        # Vérifie si la ligne contenant le stream_id existe et ne contient pas "on"
        if grep -q "^[^|]*|$stream_id|[^|]*|" "$file" && ! grep -q "^[^|]*|$stream_id|on|" "$file"; then
            echo "Ligne trouvée pour $stream_id et elle ne contient pas 'on', suppression..."
            escaped_stream=$(echo "$stream_id" | sed 's/\//\\\//g')
            sed -i "/^[^|]*|$escaped_stream/d" "$file"
        fi

        echo "Processus ffmpeg pour le flux $stream_id arrêté."
    else
        echo "Aucun processus ffmpeg en cours pour le flux $stream_id."
    fi
}

start_msg() {
    local msg_id="$1"
    local attempts=5  # Nombre de tentatives
    local wait_time=3  # Temps d'attente entre les tentatives (en secondes)

    # Obtenir l'adresse IP de l'hôte
    HOST=$(hostname -I | awk '{print $1}')  # Utiliser $() pour l'assignation
    MESSAGE="{\"$HOST\":\"$msg_id\"}"  # Utiliser des guillemets doubles pour JSON

    # Boucle de tentatives pour envoyer le message
    for ((i=1; i<=attempts; i++)); do
        # Publier les informations sur le topic MQTT
        if mosquitto_pub -h "$BROKER_IP" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$TOPIC" -m "$MESSAGE"; then
            echo "Message envoyé : $MESSAGE"
            return  # Sortir de la fonction si l'envoi a réussi
        else
            echo "Erreur lors de l'envoi du message MQTT, tentative $i sur $attempts."
            sleep "$wait_time"  # Attendre avant de réessayer
        fi
    done

    echo "Échec de l'envoi du message après $attempts tentatives."
}

# Boucle infinie
while true; do
    # Envoyer un Echo "Run"
    start_msg "RUN"

    # Enregistrer le temps de début de la boucle
    loop_start_time=$(date +%s)

    # Lire le fichier pid.conf ligne par ligne
    while IFS="|" read -r type_id stream_id status profil_id; do
        echo "arg_depart : $type_id | $stream_id | $status | $profil_id"
        current_time=$(date +%s)  # Obtenir le temps actuel
        elapsed_time=$((current_time - loop_start_time))  # Calculer le temps écoulé
        last_segment=$(basename "$stream_id")

        # Vérifie si le flux est actif
        if [[ "$status" == "on" ]]; then
            # Vérifie si le processus ffmpeg n'est pas déjà en cours
            if ! kill -0 "${ffmpeg_pids[$last_segment]}" 2>/dev/null; then
                echo "Lancement du processus ffmpeg pour le flux $stream_id..."
                start_ffmpeg "$type_id" "$stream_id" "$profil_id" # Passer l'ID du flux à la fonction
            else
                echo "Le processus ffmpeg est déjà en cours pour le flux $stream_id, PID : ${ffmpeg_pids[$stream_id]}"
            fi



            if [[ "$profil_id" != "${ffmpeg_prof[$last_segment]}" ]]; then
                echo "Condition changée [Diff Profil], arrêt du processus ffmpeg pour le flux $stream_id..."
                stop_ffmpeg "$stream_id"  # Passer l'ID du flux à la fonction
            fi

        else
            # Si le flux est désactivé, arrêter le processus ffmpeg pour ce stream_id
            echo "Condition changée, arrêt du processus ffmpeg pour le flux $stream_id..."
            stop_ffmpeg "$stream_id"  # Passer l'ID du flux à la fonction
        fi

        # Vérifier si le temps écoulé a dépassé le seuil
        if [[ $elapsed_time -gt 60 ]]; then  # Seuil de 60 secondes (ajustable)
            echo "BUG détecté : La boucle ne fonctionne pas correctement."
            start_msg "BUG"# Envoyer un message BUG
            break  # Sortir de la boucle interne
        fi

        sleep 2  # Pause pour éviter une boucle trop rapide

    done < "$file" # Rediriger l'entrée vers le fichier

    # Vérification du fichier toutes les 2 secondes
    sleep 2
done
