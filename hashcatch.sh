#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <interface> <bssid>"
    exit 1
fi

INTERFACE=$1
TARGET_BSSID=$2
OUTPUT_FILE="session/airodump_capture"

# Função para capturar pacotes EAPOL
capture_eapol() {
    local bssid=$1
    local ch=$2
    local output_file="session/hackdrone_${bssid}"
    echo "Iniciando captura no canal $ch para o BSSID $bssid..."
    sudo airodump-ng --ivs -w "$output_file" -c "$ch" --bssid "$bssid" "$INTERFACE" --write-interval 1
    
    echo "Verificando pacotes EAPOL..."
    if sudo aircrack-ng -a2 -w /dev/null "${output_file}-01.cap" | grep -q "1 handshake"; then
        echo "Pacote EAPOL capturado com sucesso!"
        return 0
    else
        echo "Nenhum pacote EAPOL capturado ainda."
        return 1
    fi
}

# Verifica se a interface está em modo monitor
monitor_mode=$(iwconfig "$INTERFACE" 2>&1 | grep 'Mode:Monitor')
if [[ ! $monitor_mode ]]; then
    echo "Erro: A interface $INTERFACE não está em modo monitor."
    exit 1
fi

# Extrai BSSIDs e canais do arquivo CSV
bssids_chs=$(awk -F, '/Station/{flag=0} /BSSID/{flag=1; next} flag {print $1, $4}' "${OUTPUT_FILE}-01.csv")

# Itera sobre a lista de BSSIDs e canais
echo "$bssids_chs" | while read -r bssid ch; do
    if [ "$bssid" == "$TARGET_BSSID" ]; then
        echo "BSSID $bssid encontrado no canal $ch."

        # Captura pacotes EAPOL no canal correto
        capture_eapol "$bssid" "$ch"
        eapol_captured=$?

        if [ $eapol_captured -eq 0 ]; then
            echo "Captura de pacotes EAPOL concluída para o BSSID $bssid."
            rm -f "${output_file}-01.csv"  # Remove arquivos intermediários para liberar espaço
            break
        else
            echo "Nenhum pacote EAPOL capturado."
        fi
        break
    fi
done
