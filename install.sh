#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMBA_SERVER="192.168.15.212"
SAMBA_SHARE="santamaria"
MOUNT_POINT="/media/SantaMaria"
CREDS_FILE="/etc/samba/credentials-santamaria"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Instalação: Samba como Disco de Rede (SantaMaria)       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo

# Verificar privilégios root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Este script deve ser executado como root"
    exit 1
fi

# Pedir credenciais interativamente
echo "🔐 Credenciais Samba:"
read -p "   Usuário: " SAMBA_USER
read -sp "   Senha: " SAMBA_PASS
echo
echo

# Verificar se cifs-utils está instalado
echo "📦 Verificando dependências..."
if ! command -v mount.cifs &> /dev/null; then
    echo "❌ ERRO: cifs-utils não está instalado"
    echo ""
    echo "📦 Instale com:"
    echo "   sudo apt-get update && sudo apt-get install cifs-utils"
    exit 1
fi
echo "   ✓ mount.cifs encontrado"

# Desmontar montagem anterior se existir
echo
echo "🔌 Limpando montagens antigas..."
if mountpoint -q /mnt/santamaria 2>/dev/null; then
    echo "   Desmontando /mnt/santamaria..."
    umount -l /mnt/santamaria || true
fi

# Parar serviços antigos
systemctl stop samba-mount.service 2>/dev/null || true
systemctl stop samba-mount-retry.service 2>/dev/null || true
systemctl disable samba-mount.service 2>/dev/null || true
systemctl disable samba-mount-retry.service 2>/dev/null || true

# Remover units antigas
rm -f /etc/systemd/system/samba-mount.service
rm -f /etc/systemd/system/samba-mount-retry.service
rm -f /etc/systemd/system/media-santamaria.*

# Criar diretório de credenciais
echo
echo "🔐 Salvando credenciais..."
mkdir -p "$(dirname "$CREDS_FILE")"

cat > "$CREDS_FILE" << EOF
username=$SAMBA_USER
password=$SAMBA_PASS
EOF

chmod 600 "$CREDS_FILE"
echo "   ✓ Credenciais em: $CREDS_FILE (chmod 600)"

# Criar ponto de montagem
echo
echo "📁 Criando ponto de montagem..."
mkdir -p "$MOUNT_POINT"
chmod 755 "$MOUNT_POINT"
echo "   ✓ $MOUNT_POINT criado"

# Instalar systemd units
echo
echo "🔧 Instalando units systemd..."
cp "$SCRIPT_DIR/media-SantaMaria.mount" /etc/systemd/system/
cp "$SCRIPT_DIR/media-SantaMaria.automount" /etc/systemd/system/
chmod 644 /etc/systemd/system/media-SantaMaria.*
echo "   ✓ Units instaladas"

# Recarregar systemd
echo
echo "🔄 Recarregando systemd..."
systemctl daemon-reload
echo "   ✓ systemd recarregado"

# Habilitar units
echo
echo "▶️  Habilitando units para boot automático..."
systemctl enable media-SantaMaria.automount
systemctl enable media-SantaMaria.mount
echo "   ✓ Units habilitadas"

# Iniciar montagem
echo
echo "🔗 Iniciando montagem..."
if systemctl start media-SantaMaria.mount; then
    echo "   ✓ Montagem iniciada"
else
    echo "   ⚠ Falha ao montar (rede pode não estar pronta)"
fi

# Verificação
echo
echo "📊 Verificação:"
if mountpoint -q "$MOUNT_POINT"; then
    echo "   ✓ Disco montado em: $MOUNT_POINT"
    echo ""
    df -h "$MOUNT_POINT" | tail -1 | awk '{print "   Tamanho:", $2, "Usado:", $3, "Disponível:", $4}'
else
    echo "   ⚠ Disco não está montado"
    echo "   Verifique com: journalctl -u media-SantaMaria.mount -n 20"
fi

echo
echo "════════════════════════════════════════════════════════════"
echo "✅ Instalação concluída!"
echo
echo "📌 Próximos passos:"
echo "   1. Abra o gerenciador de arquivos (Files/Nemo)"
echo "   2. Procure por 'SantaMaria' em 'Outros locais' ou 'Rede'"
echo "   3. O disco deve aparecer como volume de rede"
echo
echo "📋 Comandos úteis:"
echo "   systemctl status media-SantaMaria.mount"
echo "   journalctl -u media-SantaMaria.mount -f"
echo "   df -h /media/SantaMaria"
echo "════════════════════════════════════════════════════════════"
