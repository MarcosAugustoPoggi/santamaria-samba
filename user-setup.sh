#!/bin/bash
set -euo pipefail

MOUNT_POINT="/media/SantaMaria"

echo "Verificando Santa Maria Samba..."
echo

if [[ ! -d "$MOUNT_POINT" ]]; then
    echo "❌ Erro: $MOUNT_POINT não existe"
    echo "   Execute como root primeiro: sudo bash ~/Code/utils/santamaria/install.sh"
    exit 1
fi

if ! mountpoint -q "$MOUNT_POINT"; then
    echo "⚠ Aviso: Disco não está montado no momento"
    echo "   Será montado automaticamente quando acessar"
fi

echo "✅ Pronto! Acesse em:"
echo "   cd /media/SantaMaria"
echo "   ls -la /media/SantaMaria"
echo
echo "O disco deve aparecer como volume de rede no gerenciador de arquivos."
