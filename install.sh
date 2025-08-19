#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP_DIR"

link_file() {
    src=$1
    dest=$2

    if [ -f "$dest" ] || [ -L "$dest" ]; then
        echo "备份 $dest 到 $BACKUP_DIR"
        mv "$dest" "$BACKUP_DIR/"
    fi

    echo "创建软链接 $dest -> $src"
    ln -s "$src" "$dest"
}

echo "=== 开始部署 dotfiles ==="

link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

echo "✅ dotfiles 部署完成"