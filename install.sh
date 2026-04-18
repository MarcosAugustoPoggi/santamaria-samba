#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="samba-mount.sh"
INSTALL_PATH="/usr/local/bin/$SCRIPT_NAME"
SERVICE_DIR="/etc/systemd/system"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║       Instalação: Montagem Samba (Santa Maria)            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo

# Verificar privilégios root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Este script deve ser executado como root (use: sudo ./install.sh)"
    exit 1
fi

# Verificar dependências
echo "📦 Verificando dependências..."
if ! command -v mount.cifs &> /dev/null; then
    echo "❌ cifs-utils não instalado"
    echo "   Debian/Ubuntu: sudo apt-get install cifs-utils"
    echo "   RHEL/CentOS:   sudo yum install cifs-utils"
    exit 1
fi
echo "   ✓ mount.cifs encontrado"

# Copiar script
echo
echo "📝 Instalando script..."
cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_PATH"
chmod 755 "$INSTALL_PATH"
echo "   ✓ Script instalado em $INSTALL_PATH"

# Copiar systemd units
echo
echo "🔧 Instalando serviços systemd..."
cp "$SCRIPT_DIR/samba-mount.service" "$SERVICE_DIR/"
cp "$SCRIPT_DIR/samba-mount-retry.service" "$SERVICE_DIR/"
systemctl daemon-reload
echo "   ✓ Serviços instalados"

# Criar diretório de montagem
mkdir -p /mnt/santamaria
chmod 755 /mnt/santamaria
echo
echo "📁 Diretório de montagem criado em /mnt/santamaria"

# Habilitar e iniciar
echo
echo "▶️  Habilitando serviço para inicializar no boot..."
systemctl enable samba-mount.service
systemctl enable samba-mount-retry.service
echo "   ✓ Serviço habilitado"

# Iniciar montagem
echo
echo "🔗 Iniciando montagem..."
if systemctl start samba-mount.service; then
    echo "   ✓ Montagem iniciada com sucesso"
else
    echo "   ⚠ Falha ao iniciar montagem (verifique com: journalctl -u samba-mount -n 20)"
fi

# Status
echo
echo "📊 Status:"
systemctl status samba-mount.service --no-pager || true

# Instruções para usuários
echo
echo "════════════════════════════════════════════════════════════"
echo "✅ Instalação concluída!"
echo
echo "📌 Próximos passos para cada usuário:"
echo "   1. Execute como usuário normal:"
echo "      bash $SCRIPT_DIR/user-setup.sh"
echo
echo "   2. Acesse o compartilhamento:"
echo "      cd ~/santamaria"
echo "      ls -la"
echo
echo "📋 Comandos úteis:"
echo "   systemctl status samba-mount           # Ver status"
echo "   journalctl -u samba-mount -n 20       # Ver logs"
echo "   /usr/local/bin/samba-mount.sh status  # Verificar montagem"
echo "════════════════════════════════════════════════════════════"
