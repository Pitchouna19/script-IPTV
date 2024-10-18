#!/bin/bash

#!/bin/bash
# Script pour écouter sur le topic /client/info et maintenir un tableau JSON unique basé sur l'IP
BROKER_IP="PPP"
MQTT_USER="USPAS"
MQTT_PASS="PASW"
TOPIC="/client/infomap"

HOST=$(hostname -I | awk '{print $1}')  # Prend la première IP trouvée

# Déclaration d'un tableau associatif pour stocker les PIDs
declare -A ffmpeg_pids
declare -A ffmpeg_prof
declare -A proces_id
declare -A stname_id
declare -A resolus_id
declare -A brate_id
declare -A fpsvid_id

file="/root/pid/pid.conf"

# Fonction pour obtenir la couleur en fonction du statut
get_status_color() {
    case "$1" in
        "on") echo -e "\e[32m$1\e[0m" ;;  # Vert
        "off") echo -e "\e[31m$1\e[0m" ;; # Rouge
        *) echo -e "\e[33m$1\e[0m" ;;     # Jaune
    esac
}

# Fonction pour lancer ffmpeg avec une URL d'entrée
start_ffmpeg() {
    local id="$1"
    local type_id="$2"
    local stream_id="$3"  # Prendre l'ID du flux comme argument
    local name_id="$4"
    local profil_id="$5"  # Prendre l'ID du profil comme argument
    local option_vid="$6"  # Prendre l'ID du profil comme argument
    local bitrate_id="$7"  # Prendre l'ID du profil comme argument
    local fps_id="$8"  # Prendre l'ID du profil comme argument

    # Chemin du fichier profil contenant la commande ffmpeg
    local profil_file="/root/encprofil/$profil_id"

    # Vérifier si le fichier profil existe
    if [[ -f "$profil_file" ]]; then
        echo "Lancement du proces "$id" ffmpeg avec le profil : $profil_id pour le flux : $stream_id"

        # Lire la commande à partir du fichier de profil
        cmd=$(sed -e "s#\$1#$type_id#g" -e "s#\$2#$stream_id#g" -e "s#\$3#$name_id#g" -e "s#\$4#$option_vid#g" -e "s#\$5#$bitrate_id#g" -e "s#\$6#$fps_id#g" "$profil_file")

        # Exécuter la commande et récupérer directement le PID de ffmpeg
        eval "$cmd" &

        #last_segment=$(basename "$name_id")
        
        ffmpeg_pid=""
        attempts=10  # Nombre maximum de tentatives
        while [[ -z "$ffmpeg_pid" && $attempts -gt 0 ]]; do
            sleep 3  # Attendre 3 secondes avant chaque tentative

            if [[ "$profil_id" == *"ffmpeg"* ]]; then
                ffmpeg_pid=$(pgrep -n -f "ffmpeg.*$name_id")  # Récupérer le PID de ffmpeg
            elif [[ "$profil_id" == *"gst"* ]]; then
                ffmpeg_pid=$(pgrep -n -f "gst-launch.*$name_id")  # Récupérer le PID de gst-launch
            else
                echo "Profil non reconnu : $profil_id"                
            fi

            attempts=$((attempts - 1))  # Décrémenter le compteur de tentatives
        done
        
        # Vérifier si on a bien récupéré un PID
        if [[ -n "$ffmpeg_pid" ]]; then
            proces_id["$id"]="$id"  # Enregistrer le PID dans le tableau associatif
            ffmpeg_pids["$id"]="$ffmpeg_pid"  # Enregistrer le PID dans le tableau associatif
            stname_id["$id"]="$name_id"  # Enregistrer l option bitrate dans le tableau associatif
            ffmpeg_prof["$id"]="$profil_id"  # Enregistrer le Profil dans le tableau associatif
            resolus_id["$id"]="$option_vid"  # Enregistrer l option resolution dans le tableau associatif
            brate_id["$id"]="$bitrate_id"  # Enregistrer l option bitrate dans le tableau associatif
            fpsvid_id["$id"]="$fps_id"  # Enregistrer l option bitrate dans le tableau associatif

            echo "Processus $id ffmpeg lancé pour le flux $stream_id avec PID : $ffmpeg_pid"
        else
            echo "Erreur : Impossible de récupérer le PID du processus ffmpeg pour le flux $stream_id."
        fi
    else
        echo "Erreur : le fichier profil $profil_file n'existe pas."
    fi
}


# Fonction pour arrêter ffmpeg pour un stream_id donné
stop_ffmpeg() {
    local id="$1"
    local stream_id="$2"
    local status="$3"
    local name="$4"

    last_segment=$(basename "$stream_id")

    if [[ -n "${ffmpeg_pids[$id]}" && -e /proc/${ffmpeg_pids[$id]} && -n "${proces_id[$id]}" ]]; then
        echo "Arrêt du processus $id ffmpeg pour le flux $last_segment avec PID : ${ffmpeg_pids[$id]}"
        
        # Tenter d'arrêter le processus en douceur
        kill "${ffmpeg_pids[$id]}"
        sleep 2  # Attendre un peu pour que le processus se termine

        # Vérifier si le processus est toujours en cours
        if kill -0 "${ffmpeg_pids[$id]}" 2>/dev/null; then
            echo "Le processus ne s'est pas arrêté, forçage de l'arrêt avec SIGKILL..."
            kill -9 "${ffmpeg_pids[$id]}"  # Forcer l'arrêt avec SIGKILL
        fi
        
        # Supprimer le ID du tableau associatif
        unset proces_id["$id"]
        # Supprimer le PID du tableau associatif
        unset ffmpeg_pids["$id"]
        # Supprimer le PROFIL du tableau associatif
        unset ffmpeg_prof["$id"]
        # Supprimer l option RESOLUTION du tableau associatif
        unset resolus_id["$id"]
        # Supprimer l option BITERATE du tableau associatif
        unset brate_id["$id"]
        # Supprimer l option NAME STREAM du tableau associatif
        unset stname_id["$id"]
        # Supprimer l option FPS STREAM du tableau associatif
        unset fpsvid_id["$id"]
        
        
        # Fonction Modif des Status SB et OFF et RE
        modif_status "$id" "$stream_id" "$status" "$name"

        echo "Processus ffmpeg pour le flux $stream_id arrêté."
    else
        echo "Aucun processus ffmpeg en cours pour le flux $stream_id."

        # Fonction Modif des Status SB et OFF et RE
        modif_status "$id" "$stream_id" "$status" "$name"
    fi
}

modif_status() {
    
    local status_id="$1"
    local status_stream_id="$2"
    local status="$3"
    local name="$4"

    echo "$status_id"
    echo "$status_stream_id"  
    echo "$status"
    echo "$name"       

    echo "################################ modif_status ###########################################"

    # Vérifie si la ligne contenant le stream_id existe et contient pas "off" ou "sb" ou ""
        
        if grep -q "^$status_id|" "$file" && [[ "$status" == "re" ]]; then

                echo "#########################################################################################"
                echo "Ligne trouvée pour $status_id et elle contient 're', conversion en 'on' pour le replay..."
                echo "#########################################################################################"
                
                sed -i "/^$status_id|/ s/^\(\([^|]*|\)\{4\}\)re|/\1on|/" "$file"

        elif grep -q "^$status_id|" "$file" && [[ "$status" == "off" ]]; then

                echo "#########################################################################################"
                echo "Ligne trouvée pour $status_id et elle contient  'Off', suppression..."
                echo "#########################################################################################"

                sed -i "/^$status_id|/d" "$file"

        elif grep -q "^$status_id|" "$file" && [[ "$status" == "sb" ]]; then

                echo "#########################################################################################"
                echo "Ligne trouvée pour $status_id et elle contient  'sb', ne rien faire ..."
                echo "#########################################################################################"

                # Verification Ultime pour fermer les stream correspondant au 'Strean'
                #last_segment=$(basename "$status_stream_id")
        
                ffmpeg_pid_ultim=""
                ffmpeg_pid_ultim=$(pgrep -n -f "ffmpeg.*$name")  # Récupérer le PID le plus récent correspondant gst-launch
                ffmpeg_pid_ultim=$(pgrep -n -f "gst-launch.*$name")
                # Tenter d'arrêter le processus en douceur
                if [[ -n "$ffmpeg_pid_ultim" ]]; then
                    # Code à exécuter si ffmpeg_pid_ultim n'est pas vide
                    echo "La variable ffmpeg_pid_ultim contient : $ffmpeg_pid_ultim"
                    kill "$ffmpeg_pid_ultim"
                    sleep 2  # Attendre un peu pour que le processus se termine
                fi                

                # Vérifier si le processus est toujours en cours
                if kill -0 "$ffmpeg_pid_ultim" 2>/dev/null; then
                    echo "Le processus ne s'est pas arrêté, forçage de l'arrêt avec SIGKILL..."
                    kill -9 "$ffmpeg_pid_ultim"  # Forcer l'arrêt avec SIGKILL
                fi
                


        fi

}

start_msg() {
    local msg_id="$1"
    local attempts=60  # Nombre de tentatives
    local wait_time=3  # Temps d'attente entre les tentatives (en secondes)

    # Obtenir l'adresse IP de l'hôte
    HOST=$(hostname -I | awk '{print $1}')  # Utiliser $() pour l'assignation
    MESSAGE="{\"ip\":\"$HOST\",\"send\":\"$msg_id\"}"  # Utiliser des guillemets doubles pour JSON

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

# Fonction pour traiter les messages JSON reçus
update_files() {
    local message="$1"
    
    # Extraire les valeurs du JSON
    ip=$(echo "$message" | jq -r '.ip')
    cmd=$(echo "$message" | jq -r '.cmd')
    action=$(echo "$message" | jq -r '.action')

    # Comparer l'IP reçue avec l'IP de la machine
    if [[ "$ip" == "$HOST" ]]; then
        echo "IP correspondante : $ip. Traitement en cours."

        # Si 'action' est 'add', appliquer la logique de vérification avant d'ajouter
        if [[ "$action" == "add" ]]; then
            # Extraire l'id et le 4ème champ
            id=$(echo "$cmd" | cut -d'|' -f1)
            str=$(echo "$cmd" | cut -d'|' -f4)

            # Vérifier si l'id existe au début d'une ligne dans le fichier
            if grep -q "^$id|" "$file"; then
                echo "ID $id déjà présent dans $file. Aucune ligne ajoutée."
                start_msg "ERR-ID -> ID $id déjà présent dans $file. Aucune ligne ajoutée."
            # Vérifier si le 4ème champ existe déjà dans cette position sur une ligne
            elif grep -q "|$str|" "$file"; then
                echo "Le champ '$str' existe déjà en 4ème position. Aucune ligne ajoutée."
                start_msg "ERR-NAME -> Le champ '$str' existe déjà en 4ème position. Aucune ligne ajoutée."
            else
                # Ajouter la ligne si aucune correspondance n'est trouvée
                echo "$cmd" | sudo tee -a "$file" > /dev/null
                echo "Ligne ajoutée dans $file : $cmd"
                start_msg "Add [OK]"
            fi
        fi

        if [[ "$action" == "modif" ]]; then
            # Extraire l'ID et le 4ème champ
            id=$(echo "$cmd" | cut -d'|' -f1)
            str=$(echo "$cmd" | cut -d'|' -f4)

            # Vérifier si l'ID existe en début de ligne
            if grep -q "^$id|" "$file"; then
                # Vérifier si le 4ème champ (str) n'existe pas déjà en 4ème position
                if ! awk -F'|' -v str="$str" '$4 == str { exit 0 } END { exit 1 }' "$file"; then
                    # Modifier la ligne correspondant à l'ID
                    escaped_cmd=$(echo "$cmd" | sed 's/[\/&]/\\&/g')
                    sudo sed -i "/^$id|/c\\$escaped_cmd" "$file"
                    echo "Ligne modifiée dans $file : $cmd"
                    start_msg "Modif [OK]"
                else
                    echo "Erreur : Le champ existe déjà en 4ème position. Modification annulée."
                    start_msg "ERR-NAME -> Le champ $str existe déjà en 4ème position. Modification annulée."
                fi
            else
                echo "Erreur : ID $id non trouvé dans $file. Modification annulée."
                start_msg "ERR-ID -> ID $id non trouvé dans $file. Modification annulée."
            fi
        fi

        if [[ "$action" == "all-off" ]]; then
            # Remplacer 'on' par 'sb' dans le fichier
            sudo sed -i 's/on/off/g' "$file"
            echo "Tous les termes 'on' ont été remplacés par 'sb' dans $file"
            start_msg "All-Off [OK]"

            # Remplacer 'on' par 'sb' dans le fichier
            sudo sed -i 's/sb/off/g' "$file"
            echo "Tous les termes 'on' ont été remplacés par 'sb' dans $file"
            start_msg "All-Off [OK]"
        fi

        if [[ "$action" == "all-sb" ]]; then
            # Remplacer 'on' par 'sb' dans le fichier
            sudo sed -i 's/on/sb/g' "$file"
            echo "Tous les termes 'on' ont été remplacés par 'sb' dans $file"
            start_msg "All-Sb [OK]"
        fi

        if [[ "$action" == "all-on" ]]; then
            # Remplacer 'on' par 'sb' dans le fichier
            sudo sed -i 's/sb/on/g' "$file"
            echo "Tous les termes 'on' ont été remplacés par 'sb' dans $file"
            start_msg "All-On [OK]"
        fi

        # Si 'action' est 'rebout', ajouter une ligne 'reboot' au fichier
        if [[ "$action" == "rebout" ]]; then
            echo "reboot" | sudo tee -a "$file" > /dev/null
            echo "Ligne 'reboot' ajoutée dans $file"

            # envoyer msg
            start_msg "Reboot [OK]"
        fi

        # Si 'action' est 'liste' et 'cmd' est 'on',  renvoi la liste des lignes avec 'on' en 5eme position
        if [[ "$action" == "liste" && "$cmd" == "on" ]]; then
            # Extraire les lignes avec 'on' en 5ème position et les formater en JSON compact
            result=$(awk -F'|' '$5 == "on" { print "{\"line\": \"" $0 "\"}" }' "$file" | jq -s -c '.')

            if [[ -n "$result" && "$result" != "[]" ]]; then
                # Envoyer le JSON compact avec start_msg
                start_msg "$result"
            else
                # Si aucune ligne ne correspond
                echo "Aucune ligne avec 'on' en 5ème position trouvée."
                start_msg "ERR-LISTE-ON-NULL"
            fi
        fi

        # Si 'action' est 'liste' et 'cmd' est 'off',  renvoi la liste des lignes avec 'on' en 5eme position
        if [[ "$action" == "liste" && "$cmd" == "off" ]]; then
            # Extraire les lignes avec 'on' en 5ème position et les formater en JSON compact
            result=$(awk -F'|' '$5 == "off" { print "{\"line\": \"" $0 "\"}" }' "$file" | jq -s -c '.')

            if [[ -n "$result" && "$result" != "[]" ]]; then
                # Envoyer le JSON compact avec start_msg
                start_msg "$result"
            else
                # Si aucune ligne ne correspond
                echo "Aucune ligne avec 'on' en 5ème position trouvée."
                start_msg "ERR-LISTE-OFF-NULL"
            fi
        fi

        # Si 'action' est 'liste' et 'cmd' est 'sb',  renvoi la liste des lignes avec 'on' en 5eme position
        if [[ "$action" == "liste" && "$cmd" == "sb" ]]; then
            # Extraire les lignes avec 'on' en 5ème position et les formater en JSON compact
            result=$(awk -F'|' '$5 == "sb" { print "{\"line\": \"" $0 "\"}" }' "$file" | jq -s -c '.')

            if [[ -n "$result" && "$result" != "[]" ]]; then
                # Envoyer le JSON compact avec start_msg
                start_msg "$result"
            else
                # Si aucune ligne ne correspond
                echo "Aucune ligne avec 'on' en 5ème position trouvée."
                start_msg "ERR-LISTE-SB-NULL"
            fi
        fi

        if [[ "$action" == "liste" && "$cmd" == "all" ]]; then
            # Extraire toutes les lignes du fichier et les formater en JSON compact
            result=$(awk -F'|' '{ print "{\"line\": \"" $0 "\"}" }' "$file" | jq -s -c '.')

            if [[ -n "$result" && "$result" != "[]" ]]; then
                # Envoyer le JSON compact avec start_msg
                start_msg "$result"
            else
                # Si le fichier est vide
                echo "Le fichier est vide ou aucune ligne n'a été trouvée."
                start_msg "ERR-LISTE-ALL-NULL"
            fi
        fi

        if [[ "$action" == "liste" && ! "$cmd" == "all" && ! "$cmd" == "on" ]]; then
            # Extraire les lignes contenant la valeur de $cmd dans l'un des champs
            result=$(awk -F'|' -v cmd="$cmd" '$0 ~ cmd { print "{\"line\": \"" $0 "\"}" }' "$file" | jq -s -c '.')

            if [[ -n "$result" && "$result" != "[]" ]]; then
                # Envoyer le JSON compact avec start_msg
                start_msg "$result"
            else
                # Si aucune ligne ne correspond ou fichier vide
                echo "Aucune ligne contenant '$cmd' n'a été trouvée."
                start_msg "ERR-PAS-DE-CHAINE-NAME"
            fi
        fi

        
    else
        echo "IP non correspondante : $ip. Aucune action effectuée."
    fi
}

# Écouter les messages sur le topic et traiter chaque message
mosquitto_sub -h "$BROKER_IP" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$TOPIC" | while read -r message

do
    # Afficher le message reçu pour déboguer
    echo "Message reçu : $message"

    # Mettre à jour ou ajouter le client dans le fichier
    update_files "$message"
done &


# Fonction pour vérifier si les PID dans le tableau ffmpeg_pids sont toujours actifs
check_ffmpeg_pids() {
    for id in "${!ffmpeg_pids[@]}"; do
        local pid="${ffmpeg_pids[$id]}"
        
        # Vérifie si le processus avec ce PID existe toujours
        if kill -0 "$pid" 2>/dev/null; then
            echo "Le processus $id avec PID $pid est toujours actif."
        else
            echo "Le processus $id avec PID $pid n'existe plus. Nettoyage..."
            # Supprimer les données associées du processus
            unset proces_id["$id"]
            unset ffmpeg_pids["$id"]
            unset stname_id["$id"]
            unset ffmpeg_prof["$id"]
            unset resolus_id["$id"]
            unset brate_id["$id"]
            unset fpsvid_id["$id"]
        fi
    done
}


# Boucle infinie
while true; do
    # Envoyer un Echo "Run"
    #start_msg "RUN"

    # Enregistrer le temps de début de la boucle
    loop_start_time=$(date +%s)

    # Vérifier les PID enregistrés avant de traiter les lignes du fichier
    check_ffmpeg_pids    

    # Lire le fichier pid.conf ligne par ligne
    while IFS="|" read -r id type_id stream_id name_id status profil_id option_vid bitrate_id fps_id; do

        # Message adresser au serveur uniquement par un seul mot
        if [[  -z "$fps_id" && -z "$bitrate_id" && -z "$option_vid" && -z "$name_id" && -z "$type_id" && -z "$stream_id" && -z "$status" && -z "$profil_id" ]]; then
            # Dans ce cas, il n'y a qu'un seul mot (type_id)
            if [[ "$id" == "reboot" ]]; then

                echo "#############################################"
                echo "#                                           #"
                echo "#   Nettoyage du fichier mot |reboot|..     #"
                echo "#                                           #"
                echo "#############################################"

                start_msg "REBOOT" # Envoyer un message Reboot

                for key in "${!ffmpeg_pids[@]}"; do
                    echo "Clé : $key, Valeur : ${ffmpeg_pids[$key]}"
                    stop_ffmpeg "$key" "NON_DELL"
                    echo "arret du processus stream_id : $key du PID : $${ffmpeg_pids[$key]}"
                    sleep 4
                done
                sed -i '/reboot/d' "$file"                
                echo "Rebooting the script...[Corp MAP]"

                exec "$0"  # Relancer le script actuel
            fi
        fi

        status_colored=$(get_status_color "$status")
        echo ""
        echo -e "\e[32marg_depart : $id | $type_id | $stream_id | $name_id | $status_colored | $profil_id | $option_vid | $bitrate_id\e[0m"
        echo ""
        current_time=$(date +%s)  # Obtenir le temps actuel
        elapsed_time=$((current_time - loop_start_time))  # Calculer le temps écoulé
        last_segment=$(basename "$stream_id")
        echo $status

        # Vérifie si le flux est actif
        if [[ "$status" == "on" ]]; then
            
            # Vérifie si le processus ffmpeg n'est pas déjà en cours
            if [[ "${proces_id[$id]}" != "$id" ]]; then
                echo "Lancement du processus $id ffmpeg pour le flux $stream_id..."
                start_ffmpeg "$id" "$type_id" "$stream_id" "$name_id" "$profil_id" "$option_vid" "$bitrate_id" "$fps_id" # Passer l'ID du flux à la fonction
                echo "Attente delais entre lancement de 4 secondes..."
                sleep 4
            else
                echo "Le processus $id ffmpeg est déjà en cours pour le flux $stream_id, PID : ${ffmpeg_pids[$id]}"
            
                if [[ "$profil_id" != "${ffmpeg_prof[$id]}" ]] || [[ "$option_vid" != "${resolus_id[$id]}" ]] || [[ "$bitrate_id" != "${brate_id[$id]}" ]] || [[ "$name_id" != "${stname_id[$id]}" ]]; then
                echo "Condition changée [Diff Profil], arrêt du processus ffmpeg pour le flux $stream_id..."
                stop_ffmpeg "$id" "$stream_id" "$status" "$name_id" # Passer l'ID du flux à la fonction
                fi

            fi           

        else
            # Si le flux est désactivé, arrêter le processus ffmpeg pour ce stream_id
            echo "Condition changée, arrêt du processus $id ffmpeg pour le flux $stream_id..."
            stop_ffmpeg "$id" "$stream_id" "$status" "$name_id" # Passer l'ID du flux à la fonction
        fi

        # Vérifier si le temps écoulé a dépassé le seuil
        if [[ $elapsed_time -gt 60 ]]; then  # Seuil de 60 secondes (ajustable)
            echo "BUG détecté : La boucle ne fonctionne pas correctement."
            start_msg "BUG" # Envoyer un message BUG
            break  # Sortir de la boucle interne
        fi

        sleep 2  # Pause pour éviter une boucle trop rapide

    done < "$file" # Rediriger l'entrée vers le fichier

    # Vérification du fichier toutes les 2 secondes
    sleep 2
done
