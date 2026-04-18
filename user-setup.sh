#!/bin/bash
set -euo pipefail

MOUNT_POINT="/mnt/santamaria"
USER_LINK="$HOME/santamaria"

echo "Setup Santa Maria Samba para: $(whoami)"
echo

# Verificar se montagem existe
if [[ ! -d "$MOUNT_POINT" ]]; then
    echo "❌ Erro: $MOUNT_POINT não existe"
    echo "   Execute como root primeiro: sudo bash ~/Code/utils/santamaria/install.sh"
    exit 1
fi

# Criar symlink
if [[ -L "$USER_LINK" ]]; then
    echo "✓ Symlink já existe: $USER_LINK"
elif [[ -d "$USER_LINK" ]]; then
    echo "⚠ Diretório $USER_LINK já existe. Substituindo..."
    rm -rf "$USER_LINK"
    ln -s "$MOUNT_POINT" "$USER_LINK"
    echo "✓ Symlink criado"
else
    echo "Criando symlink: $USER_LINK → $MOUNT_POINT"
    ln -s "$MOUNT_POINT" "$USER_LINK"
    echo "✓ Symlink criado"
fi

echo
echo "✅ Pronto! Acesse em:"
echo "   cd ~/santamaria"
echo "   ls -la ~/santamaria"
