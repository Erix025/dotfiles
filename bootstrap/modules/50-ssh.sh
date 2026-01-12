#!/usr/bin/env bash

module_ssh() {
    if [[ "${EZSH_SSH_WRITE_KEY:-0}" != "1" ]]; then
        warn "默认跳过 SSH 私钥落盘。请运行 'ezsh ssh unlock' 通过 ssh-agent 加载密钥。"
        warn "若确需写入 ~/.ssh/github_key，请设置 EZSH_SSH_WRITE_KEY=1 后重试。"
        return 0
    fi

    log "写入 SSH 私钥"

    bw_ensure_cli
    bw_ensure_server "$BW_SERVER"
    bw_ensure_session

    local private_key=""
    private_key=$(bw_get_field "$SSH_KEY_ITEM" "sshKey.privateKey")

    local ssh_dir="$HOME/.ssh"
    ensure_dir "$ssh_dir"
    write_file_safe "$ssh_dir/github_key" "$private_key" 600
    log "SSH 私钥已写入 $ssh_dir/github_key"
}
