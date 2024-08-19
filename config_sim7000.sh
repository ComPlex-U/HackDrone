#!/bin/bash

# Script de configuração do SIM7000E no Raspberry Pi Zero 2 W com Kali Linux

# Variáveis
APN="internet"
SERIAL_PORT="/dev/ttyS0"

# Instalar dependências necessárias
echo "Instalando dependências..."
sudo apt install -y ppp minicom gpsd gpsd-clients python3-gps

# Configuração do Chat Script
echo "Configurando o chat script para PPP..."
sudo mkdir -p /etc/chatscripts
sudo bash -c "cat > /etc/chatscripts/gprs <<EOL
ABORT 'BUSY'
ABORT 'NO CARRIER'
ABORT 'ERROR'
ABORT 'NO DIALTONE'
TIMEOUT 12
'' ATZ
OK AT+CFUN=1
OK AT+CPIN?
OK AT+CREG?
OK AT+CGATT?
OK AT+CIPSHUT
OK AT+CSTT=\"$APN\"
OK AT+CIICR
OK AT+CIFSR
OK ATD*99#
CONNECT ''
EOL"

# Configuração do PPP
echo "Configurando PPP..."
sudo mkdir -p /etc/ppp/peers
sudo bash -c "cat > /etc/ppp/peers/gprs <<EOL
$SERIAL_PORT 115200
connect '/usr/sbin/chat -v -f /etc/chatscripts/gprs'
noauth
defaultroute
usepeerdns
persist
noipdefault
EOL"

# Configuração do GPSD
echo "Configurando GPSD..."
sudo bash -c "cat > /etc/default/gpsd <<EOL
START_DAEMON=\"true\"
GPSD_OPTIONS=\"-n\"
DEVICES=\"$SERIAL_PORT\"
USBAUTO=\"false\"
GPSD_SOCKET=\"/var/run/gpsd.sock\"
EOL"

# Reiniciar o serviço GPSD
echo "Reiniciando o serviço GPSD..."
sudo systemctl restart gpsd

# Automação da inicialização do PPP e GPSD
echo "Automatizando a inicialização do PPP e GPSD..."

# Adicionar PPP à inicialização
sudo bash -c "grep -qxF 'sudo pppd call gprs' /etc/rc.local || sed -i '/^exit 0/i sudo pppd call gprs' /etc/rc.local"

# Reiniciar o serviço GPSD na inicialização
sudo systemctl enable gpsd

# Finalização
echo "Configuração concluída. O sistema está configurado para conectar à internet via GSM e obter coordenadas GPS na inicialização."

# Teste manual para iniciar a conexão PPP
echo "Para testar a conexão PPP, execute: sudo pppd call gprs"

#chmod +x configurar_sim7000e.sh
