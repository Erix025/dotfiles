#!/usr/bin/env bash

module_secrets() {
    log "同步 Bitwarden secrets"

    bw_ensure_cli
    bw_ensure_server "$BW_SERVER"
    bw_ensure_session

    local -a SECRET_SPECS=(
        "ANTHROPIC_AUTH_TOKEN=ZIPLab Claude API Key:api_key"
    )

    local output=""
    local entry key spec item field value

    for entry in "${SECRET_SPECS[@]}"; do
        IFS='=' read -r key spec <<<"$entry"
        IFS=':' read -r item field <<<"$spec"
        field="${field:-password}"
        value=$(bw_get_field "$item" "$field")
        output+="export ${key}=\"${value//$'\n'/}\"\n"
    done

    local secrets_dir="$HOME/.config/secrets"
    ensure_dir "$secrets_dir"
    local dest="$secrets_dir/env"
    write_file_safe "$dest" "$output" 600
    log "secrets 已写入 $dest"
}
