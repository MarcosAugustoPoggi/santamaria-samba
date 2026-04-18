#!/bin/bash
set -euo pipefail

# Configuração Samba
SAMBA_SERVER="192.168.15.212"
SAMBA_SHARE="santamaria"
SAMBA_USER="santamaria"
SAMBA_PASS="santamaria"
MOUNT_POINT="/mnt/santamaria"
CREDS_FILE="/root/.smbcredentials"
RETRY_DELAY=5
MAX_RETRIES=30

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a /var/log/samba-mount.log
}

# Criar arquivo de credenciais
setup_credentials() {
    if [[ ! -f "$CREDS_FILE" ]]; then
        log "Criando arquivo de credenciais..."
        cat > "$CREDS_FILE" <<EOF
username=$SAMBA_USER
password=$SAMBA_PASS
EOF
        chmod 600 "$CREDS_FILE"
        log "Credenciais armazenadas em $CREDS_FILE"
    fi
}

# Aguardar rede estar disponível
wait_for_network() {
    local attempt=0
    log "Aguardando rede..."
    while ! ping -c 1 -W 2 $SAMBA_SERVER &>/dev/null; do
        if [[ $attempt -ge $MAX_RETRIES ]]; then
            log "ERRO: Servidor $SAMBA_SERVER não alcançável após $MAX_RETRIES tentativas"
            return 1
        fi
        attempt=$((attempt + 1))
        log "Tentativa $attempt/$MAX_RETRIES: servidor não alcançável, aguardando ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
    done
    log "Rede disponível, servidor alcançável"
    return 0
}

# Montar compartilhamento
mount_share() {
    # Verificar se já está montado
    if mountpoint -q "$MOUNT_POINT"; then
        log "Compartilhamento já está montado em $MOUNT_POINT"
        return 0
    fi

    # Criar ponto de montagem se não existir
    if [[ ! -d "$MOUNT_POINT" ]]; then
        mkdir -p "$MOUNT_POINT"
        log "Diretório $MOUNT_POINT criado"
    fi

    log "Montando //$SAMBA_SERVER/$SAMBA_SHARE em $MOUNT_POINT..."
    if mount -t cifs \
        "//$SAMBA_SERVER/$SAMBA_SHARE" "$MOUNT_POINT" \
        -o "credentials=$CREDS_FILE,uid=$(id -u nobody),gid=$(id -g nogroup),file_mode=0755,dir_mode=0755,noperm"; then
        log "Montagem bem-sucedida"
        return 0
    else
        log "ERRO: Falha na montagem"
        return 1
    fi
}

# Desmontar (se necessário)
unmount_share() {
    if mountpoint -q "$MOUNT_POINT"; then
        log "Desmontando $MOUNT_POINT..."
        umount -l "$MOUNT_POINT" && log "Desmontagem bem-sucedida" || log "AVISO: Falha ao desmontar"
    fi
}

main() {
    case "${1:-mount}" in
        mount)
            setup_credentials
            wait_for_network || return 1
            mount_share
            ;;
        unmount)
            unmount_share
            ;;
        remount)
            unmount_share
            sleep 2
            setup_credentials
            wait_for_network || return 1
            mount_share
            ;;
        status)
            if mountpoint -q "$MOUNT_POINT"; then
                log "✓ Compartilhamento montado em $MOUNT_POINT"
                df -h "$MOUNT_POINT"
            else
                log "✗ Compartilhamento NÃO está montado"
                return 1
            fi
            ;;
        *)
            echo "Uso: $0 {mount|unmount|remount|status}"
            exit 1
            ;;
    esac
}

main "$@"
