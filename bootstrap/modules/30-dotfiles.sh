#!/usr/bin/env bash

module_dotfiles() {
    log "同步 dotfiles 仓库"
    ensure_cmd git

    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        git -C "$DOTFILES_DIR" fetch origin main
        git -C "$DOTFILES_DIR" pull --ff-only origin main
    else
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi

    if [[ -x "$DOTFILES_DIR/install.sh" ]]; then
        log "执行 dotfiles install.sh"
        "$DOTFILES_DIR/install.sh"
    else
        warn "未找到可执行的 install.sh"
    fi
}
