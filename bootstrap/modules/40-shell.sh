#!/usr/bin/env bash

module_shell() {
    ensure_cmd zsh
    local current_shell
    current_shell=$(basename "${SHELL:-}")
    local target="zsh"
    local shell_path
    shell_path=$(command -v "$target")

    if [[ "$current_shell" == "$target" ]]; then
        log "默认 shell 已是 $target"
        return
    fi

    if ! grep -q "^$shell_path$" /etc/shells; then
        local sudo_cmd
        sudo_cmd=$(get_sudo)
        echo "$shell_path" | $sudo_cmd tee -a /etc/shells >/dev/null
    fi

    local sudo_cmd
    sudo_cmd=$(get_sudo)
    if $sudo_cmd chsh -s "$shell_path" "${USER:-$(whoami)}"; then
        log "默认 shell 已切换为 $target"
    else
        warn "切换默认 shell 失败，请手动运行: chsh -s $shell_path"
    fi
}
