#!/bin/bash

# Verifica se foram passados dois argumentos
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <interface> <bssid>"
    exit 1
fi

# Atribui os argumentos a variáveis
interface=$1
bssid=$2
csv_file="session/airodump_capture.csv"

# Verifica se o ficheiro CSV existe
if [ ! -f "$csv_file" ]; then
    echo "Ficheiro CSV não encontrado: $csv_file"
    exit 1
fi

# Procura o canal associado ao BSSID no ficheiro CSV
ch=$(grep "$bssid" "$csv_file" | awk -F',' '{print $4}' | tr -d ' ')

# Verifica se encontrou o canal
if [ -z "$ch" ]; then
    echo "BSSID $bssid não encontrado no ficheiro CSV"
    exit 1
fi

output_dir="session"
output_file="$output_dir/capture_$bssid"

mkdir -p "$output_dir"

# Executa o comando airodump-ng para capturar o handshake e verifica a presença de EAPOL
sudo airodump-ng -w "$output_file" -c "$ch" --bssid "$bssid" "$interface" | \
while IFS= read -r line; do
    if echo "$line" | grep -q "WPA handshake"; then
        echo "Pacote WPA handshake detectado, encerrando captura."
        sudo killall airodump-ng
        break
    fi
done

# chmod +x hashcatch.sh
# ./hashcatch.sh wlan1mon AA:BB:CC:DD:EE:FF
