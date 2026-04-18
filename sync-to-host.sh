#!/bin/bash
set -euo pipefail

# Script para sincronizar esses arquivos para outra máquina via SSH
# Uso: ./sync-to-host.sh user@host.local

if [[ $# -ne 1 ]]; then
    echo "Uso: $0 user@host.local"
    echo ""
    echo "Exemplo:"
    echo "  ./sync-to-host.sh marcos@ubuntu-server"
    echo "  ./sync-to-host.sh root@192.168.1.50"
    exit 1
fi

TARGET="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_PATH="Code/utils/santamaria"

echo "📤 Sincronizando para $TARGET:~/$REMOTE_PATH"
echo ""

# Verificar conectividade
if ! ssh -o ConnectTimeout=5 "$TARGET" "echo ✓ Conectado" 2>/dev/null; then
    echo "❌ Não conseguiu conectar a $TARGET"
    exit 1
fi

# Sincronizar arquivos
rsync -avz \
    --exclude=".git" \
    --exclude="*.log" \
    "$SCRIPT_DIR/" \
    "$TARGET:~/$REMOTE_PATH/"

echo ""
echo "✅ Sincronização concluída"
echo ""
echo "📌 Próximos passos no host remoto:"
echo "   ssh $TARGET"
echo "   cd ~/$REMOTE_PATH"
echo "   sudo bash install.sh"
echo "   bash user-setup.sh"
