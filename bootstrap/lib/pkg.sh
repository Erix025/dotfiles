#!/usr/bin/env bash

ensure_cmd() {
    local cmd="$1"
    local pkg="${2:-}"

    if command -v "$cmd" >/dev/null 2>&1; then
        return
    fi

    if [[ "$cmd" == "bw" ]]; then
        install_bitwarden_cli
        return
    fi

    if [[ -z "$pkg" ]]; then
        case "$cmd" in
            git) pkg="git" ;;
            curl) pkg="curl" ;;
            jq) pkg="jq" ;;
            zsh) pkg="zsh" ;;
            *) pkg="$cmd" ;;
        esac
    fi

    log "安装缺失命令: $cmd ($pkg)"
    install_package "$pkg"
}

install_package() {
    local package_name="$1"
    local os
    os=$(detect_os)

    case "$os" in
        darwin)
            if ! command -v brew >/dev/null 2>&1; then
                die "需要 Homebrew 以安装 $package_name: https://brew.sh/"
            fi
            brew install "$package_name"
            ;;
        debian)
            local sudo_cmd
            sudo_cmd=$(get_sudo)
            $sudo_cmd apt-get update -y
            $sudo_cmd apt-get install -y "$package_name"
            ;;
        redhat)
            local sudo_cmd
            sudo_cmd=$(get_sudo)
            if command -v dnf >/dev/null 2>&1; then
                $sudo_cmd dnf install -y "$package_name"
            else
                $sudo_cmd yum install -y "$package_name"
            fi
            ;;
        *)
            die "未知系统，无法安装包: $package_name"
            ;;
    esac
}

install_bitwarden_cli() {
    local os
    os=$(detect_os)

    case "$os" in
        darwin)
            install_package "bitwarden-cli"
            ;;
        debian|redhat)
            install_npm_global "@bitwarden/cli"
            ;;
        *)
            die "未知系统，无法安装 Bitwarden CLI"
            ;;
    esac
}

install_npm_global() {
    local package_name="$1"

    if ! command -v npm >/dev/null 2>&1; then
        die "需要 npm 以安装 $package_name"
    fi

    log "安装 npm 全局包: $package_name"

    local sudo_cmd
    sudo_cmd=$(get_sudo)

    if [[ -n "$sudo_cmd" ]]; then
        $sudo_cmd npm install -g "$package_name"
    else
        npm install -g "$package_name"
    fi
}

install_python_tool() {
    local tool="$1"
    local script="$2"

    if command -v "$tool" >/dev/null 2>&1; then
        return
    fi

    log "安装 Python 工具: $tool"
    curl -fsSL "$script" | sh
}

get_sudo() {
    if [[ $EUID -eq 0 ]]; then
        printf ''
        return
    fi

    if command -v sudo >/dev/null 2>&1; then
        printf 'sudo'
    else
        die "需要 sudo 或 root 权限"
    fi
}
