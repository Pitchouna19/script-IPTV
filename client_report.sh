#!/bin/bash
# Script pour envoyer les informations du client au broker MQTT

BROKER_IP="PPP"
MQTT_USER="USPAS"
MQTT_PASS="PASW"
TOPIC="/client/info"

while true; do
    # Récupérer l'IP locale
    IP_CLIENT=$(hostname -I | awk '{print $1}')

    # Récupérer la charge CPU par cœur
    #CPU_LOAD=$(awk -v INTERVAL=1 '{cpu_now=(+); total_now=(++)} {if (NR>1) {cpu_diff=cpu_now-prev_cpu; total_diff=total_now-prev_total; usage=(cpu_diff*100)/total_diff; print usage "%"}; prev_cpu=cpu_now; prev_total=total_now; fflush(); system("sleep " INTERVAL);}' <(grep 'cpu ' /proc/stat))
    
    CPU_LOAD=$(mpstat 1 1 | awk '/all/ && NR==4 {print 100 - $12}')
    
    # Récupérer le trafic réseau (octets reçus et envoyés)
    INTERFACE=eth0  # Remplacez par votre interface réseau (ex : eth0, wlan0, etc.)
    RX_BYTES_BEFORE=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    TX_BYTES_BEFORE=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
    
    sleep 1
    
    RX_BYTES_AFTER=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    TX_BYTES_AFTER=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

    RX_BYTES=$( echo "scale=2; ("$RX_BYTES_AFTER - $RX_BYTES_BEFORE") / 1024" | bc )
    TX_BYTES=$( echo "scale=2; ("$TX_BYTES_AFTER - $TX_BYTES_BEFORE") / 1024" | bc )
    
    #RX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    #TX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

    # Construire le message JSON
    MESSAGE=$(printf '{\"ip\": \"%s\", \"cpu_load\": \"%s\", \"network_in\": \"%s\", \"network_out\": \"%s\"}'         "$IP_CLIENT" "$CPU_LOAD" "$RX_BYTES" "$TX_BYTES")

    # Publier les informations sur le topic MQTT
    mosquitto_pub -h "$BROKER_IP" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$TOPIC" -m "$MESSAGE"

    # Afficher un message de succès
    if [ $? -eq 0 ]; then
        echo "Informations envoyées avec succès au broker MQTT."
    else
        echo "Erreur lors de l'envoi des informations au broker MQTT."
    fi

    # Attendre 10 secondes avant de répéter
    sleep 4
done
