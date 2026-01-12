#!/usr/bin/env bash

module_secrets() {
    log "同步 Bitwarden secrets"

    bw_ensure_cli
    bw_ensure_server "$BW_SERVER"
    bw_ensure_session

    declare -A SECRETS=(
        ["ANTHROPIC_AUTH_TOKEN"]="ZIPLab Claude API Key:api_key"
    )

    local output=""
    local key item field value

    for key in "${!SECRETS[@]}"; do
        IFS=':' read -r item field <<<"${SECRETS[$key]}"
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
