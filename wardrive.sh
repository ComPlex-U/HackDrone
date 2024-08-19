#!/bin/bash

INTERFACE=$1
OUTPUT_DIR="session"
OUTPUT_FILE="$OUTPUT_DIR/airodump_capture"
JSON_FILE="$OUTPUT_DIR/wardrive_results.json"

# Cria a pasta session se não existir
mkdir -p "$OUTPUT_DIR"

# Inicia o airodump-ng, salvando os dados na pasta session/
sudo airodump-ng --output-format csv -w "$OUTPUT_FILE" $INTERFACE > /dev/null 2>&1 &

# Função para converter o CSV para JSON
convert_csv_to_json() {
    CSV_FILE="${OUTPUT_FILE}-01.csv"
    if [ -f "$CSV_FILE" ]; then
        echo "[" > "$JSON_FILE"
        tail -n +2 "$CSV_FILE" | grep -v "BSSID" | while IFS=',' read -r bssid first_seen last_seen channel speed privacy cipher auth power beacons iv len essid key; do
            if [ ! -z "$bssid" ] && [ ! -z "$essid" ]; then
                echo "  {" >> "$JSON_FILE"
                echo "    \"name\": \"${key//\"/\\\"}\"," >> "$JSON_FILE"
                echo "    \"mac\": \"$bssid\"," >> "$JSON_FILE"
                echo "    \"latitude\": 51.5074," >> "$JSON_FILE"
                echo "    \"longitude\": -0.1278," >> "$JSON_FILE"
                echo "    \"timestamp\": \"$(date -Iseconds)\"" >> "$JSON_FILE"
                echo "  }," >> "$JSON_FILE"
            fi
        done
        sed -i '$ s/,$//' "$JSON_FILE"  # Remove a última vírgula
        echo "]" >> "$JSON_FILE"
    fi
}

# Loop para atualizar o JSON constantemente
while true; do
    sleep 30  # Atualiza a cada 30 segundos
    convert_csv_to_json
done

#chmod +x wardrive.sh
#sudo ./wardrive.sh wlan1mon