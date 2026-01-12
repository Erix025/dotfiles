#!/usr/bin/env bash

bw_ensure_cli() {
    ensure_cmd bw bitwarden-cli
}

bw_ensure_server() {
    local server="$1"
    [[ -n "$server" ]] || die "未指定 Bitwarden 服务器"
    bw config server "$server" >/dev/null
}

bw_ensure_session() {
    if [[ -n "${BW_SESSION:-}" ]]; then
        if bw status --session "$BW_SESSION" | grep -q '"status":"unlocked"'; then
            export BW_SESSION
            return
        fi
    fi

    local status
    status=$(bw status 2>/dev/null || true)

    if echo "$status" | grep -q '"status":"unauthenticated"'; then
        log "Bitwarden 未登录，开始登录..."
        bw login >/dev/null
    fi

    log "解锁 Bitwarden..."
    BW_SESSION=$(bw unlock --raw)
    [[ -n "$BW_SESSION" ]] || die "无法获取 Bitwarden 会话"
    export BW_SESSION
}

bw_get_field() {
    local item="$1"
    local field="$2"
    [[ -n "${BW_SESSION:-}" ]] || die "Bitwarden 会话未建立"

    local data
    data=$(bw get item "$item" --session "$BW_SESSION")

    local value
    value=$(echo "$data" | jq -r --arg name "$field" '.fields[]? | select(.name == $name) | .value // empty' | head -n1)

    if [[ -z "$value" ]]; then
        case "$field" in
            password|username|totp)
                value=$(echo "$data" | jq -r --arg key "$field" '.login[$key] // empty')
                ;;
            notes)
                value=$(echo "$data" | jq -r '.notes // empty')
                ;;
        esac
    fi

    if [[ -z "$value" ]]; then
        value=$(echo "$data" | jq -r --arg path "$field" '
            def dig($keys):
                reduce $keys[] as $key
                    (.; if type == "object" then .[$key] else empty end);
            (dig(($path | split("."))) // empty)
        ' 2>/dev/null)
    fi

    if [[ -z "$value" || "$value" == "null" ]]; then
        die "Bitwarden 条目 $item 缺少字段 $field"
    fi

    printf '%s' "$value"
}
