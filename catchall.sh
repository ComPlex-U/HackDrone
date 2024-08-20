#!/bin/bash

# Verifica se a interface foi passada como argumento
if [ -z "$1" ]; then
  echo "Por favor, forneça a interface como argumento."
  echo "Uso: $0 <interface>"
  exit 1
fi

ORIGINAL_INTERFACE="$1"
OUTPUT_FILE="sessions/airodump_capture"

# Coloca a interface no modo monitor
sudo airmon-ng start $ORIGINAL_INTERFACE

INTERFACE="${ORIGINAL_INTERFACE}mon"

sudo python folderMonitrFirebase.py &

sleep 2

# Executa o airodump-ng por 1 minuto e guarda o ficheiro num CSV
sudo timeout 1m airodump-ng --output-format csv -w $OUTPUT_FILE $INTERFACE

echo "Captura concluída e salva em ${OUTPUT_FILE}-01.csv"

sleep 2
break
# chmod +x catchall.sh

# ./catchall.sh wlan1
