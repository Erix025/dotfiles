#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Erix025/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BRANCH="${BRANCH:-main}"

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

get_sudo() {
    if [[ $EUID -eq 0 ]]; then
        echo ""
        return
    fi

    if have_cmd sudo; then
        echo sudo
    else
        echo ""
    fi
}

install_basic_pkg() {
    local pkg="$1"

    if have_cmd apt-get; then
        local sudo_cmd
        sudo_cmd=$(get_sudo)
        [[ -n "$sudo_cmd" ]] || { echo "sudo 不可用，请以 root 运行以安装 $pkg"; exit 1; }
        $sudo_cmd apt-get update -y
        $sudo_cmd apt-get install -y "$pkg"
    elif have_cmd dnf; then
        local sudo_cmd
        sudo_cmd=$(get_sudo)
        [[ -n "$sudo_cmd" ]] || { echo "sudo 不可用，请以 root 运行以安装 $pkg"; exit 1; }
        $sudo_cmd dnf install -y "$pkg"
    elif have_cmd yum; then
        local sudo_cmd
        sudo_cmd=$(get_sudo)
        [[ -n "$sudo_cmd" ]] || { echo "sudo 不可用，请以 root 运行以安装 $pkg"; exit 1; }
        $sudo_cmd yum install -y "$pkg"
    elif have_cmd brew; then
        brew install "$pkg"
    else
        echo "无法自动安装 $pkg，请手动安装 git/curl 后重试"
        exit 1
    fi
}

ensure_bootstrap_tool() {
    local cmd="$1"
    if have_cmd "$cmd"; then
        return
    fi
    install_basic_pkg "$cmd"
}

ensure_bootstrap_tool git
ensure_bootstrap_tool curl

if [[ -d "$DOTFILES_DIR/.git" ]]; then
    git -C "$DOTFILES_DIR" fetch origin "$BRANCH"
    if ! git -C "$DOTFILES_DIR" rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
        echo "无法获取分支 $BRANCH"
        exit 1
    fi
    git -C "$DOTFILES_DIR" checkout "$BRANCH"
    git -C "$DOTFILES_DIR" pull --ff-only origin "$BRANCH"
else
    git clone --branch "$BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

exec "$DOTFILES_DIR/bootstrap/run.sh" "$@"
