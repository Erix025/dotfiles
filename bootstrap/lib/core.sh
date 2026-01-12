#!/usr/bin/env bash

log() {
    printf '[bootstrap] %s\n' "$*"
}

warn() {
    printf '[bootstrap][warn] %s\n' "$*" >&2
}

die() {
    warn "$*"
    exit 1
}

confirm() {
    local prompt="${1:-继续?}"
    local default="${2:-n}"
    local answer
    local suffix="[y/N]"

    case "$default" in
        y|Y) suffix="[Y/n]" ;;
    esac

    read -rp "$prompt $suffix " answer
    answer="${answer:-$default}"

    case "$answer" in
        y|Y) return 0 ;;
        *)   return 1 ;;
    esac
}

detect_os() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "darwin"
        return
    fi

    if [[ -f /etc/debian_version ]]; then
        echo "debian"
        return
    fi

    if [[ -f /etc/redhat-release ]]; then
        echo "redhat"
        return
    fi

    echo "unknown"
}
