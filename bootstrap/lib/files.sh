#!/usr/bin/env bash

ensure_dir() {
    local dir="$1"
    [[ -d "$dir" ]] || mkdir -p "$dir"
}

backup_if_exists() {
    local path="$1"
    if [[ ! -e "$path" ]]; then
        return
    fi

    local backup="${path}.bak.$(date +%s)"
    mv "$path" "$backup"
    log "已备份 $path -> $backup"
}

write_file_safe() {
    local path="$1"
    local content="$2"
    local mode="${3:-600}"

    ensure_dir "$(dirname "$path")"

    local tmp
    tmp=$(mktemp)
    printf '%s' "$content" > "$tmp"

    if [[ -f "$path" ]]; then
        if cmp -s "$tmp" "$path"; then
            rm -f "$tmp"
            chmod "$mode" "$path"
            return
        fi
        backup_if_exists "$path"
    fi

    mv "$tmp" "$path"
    chmod "$mode" "$path"
}
