#!/bin/bash

# Variáveis - personalize aqui
DOMAIN="dronehacksr71"
TOKEN=""
CRON_INTERVAL="*/5 * * * *"  # Intervalo para atualizar IP a cada 5 minutos51aafec3bfdb4599bb2c3b3f60b07d2c
DUCKDNS_DIR="$HOME/duckdns"
DUCKDNS_SCRIPT="$DUCKDNS_DIR/duck.sh"
DUCKDNS_LOG="$DUCKDNS_DIR/duck.log"
SSH_PORT="22"

# Configurar o DuckDNS
setup_duckdns() {
    echo "A configurar o DuckDNS..."

    # Criar diretório e script
    mkdir -p "$DUCKDNS_DIR"
    echo "url=\"https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=\" | curl -k -o $DUCKDNS_LOG -K -" > "$DUCKDNS_SCRIPT"

    # Tornar o script executável
    chmod 700 "$DUCKDNS_SCRIPT"

    # Configurar cron job
    (crontab -l 2>/dev/null; echo "$CRON_INTERVAL $DUCKDNS_SCRIPT >/dev/null 2>&1") | crontab -
    
    echo "DuckDNS configurado com sucesso."
}

# Verificar se o SSH está ativo
check_ssh() {
    echo "A verificar o estado do SSH..."
    sudo systemctl enable ssh
    sudo systemctl start ssh

    if sudo systemctl status ssh | grep -q "active (running)"; then
        echo "SSH está ativo."
    else
        echo "Houve um problema ao ativar o SSH."
    fi
}

# Sugestão para mudar a porta SSH
suggest_ssh_port_change() {
    echo "Se deseja aumentar a segurança, considere alterar a porta padrão do SSH de $SSH_PORT para outra."
    echo "Para fazer isso, edite o ficheiro /etc/ssh/sshd_config e altere a linha Port para um valor como 2222."
    echo "Após fazer a alteração, reinicie o SSH com: sudo systemctl restart ssh"
}

# Execução das funções
setup_duckdns
check_ssh
suggest_ssh_port_change

echo "Configuração completa. Pode aceder ao seu Raspberry Pi via SSH usando o domínio $DOMAIN.duckdns.org."

#chmod +x config_duckdns.sh
