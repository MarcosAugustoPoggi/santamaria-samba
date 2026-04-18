#!/bin/bash
set -euo pipefail

# Script que cada usuário executa uma vez para criar symlink
MOUNT_POINT="/mnt/santamaria"
USER_LINK="$HOME/santamaria"

if [[ ! -d "$MOUNT_POINT" ]]; then
    echo "❌ Erro: $MOUNT_POINT não existe. Execute install.sh como root primeiro."
    exit 1
fi

if [[ -L "$USER_LINK" ]]; then
    echo "✓ Link já existe em $USER_LINK"
    exit 0
fi

if [[ -d "$USER_LINK" ]]; then
    echo "⚠ Diretório $USER_LINK já existe. Removendo..."
    rm -rf "$USER_LINK"
fi

echo "Criando symlink $USER_LINK -> $MOUNT_POINT"
ln -s "$MOUNT_POINT" "$USER_LINK"
chmod 755 "$USER_LINK"

echo "✓ Setup concluído. Acesse em: $USER_LINK"
ls -la "$USER_LINK"
