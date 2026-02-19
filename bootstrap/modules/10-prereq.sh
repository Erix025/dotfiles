#!/usr/bin/env bash

module_prereq() {
    log "安装基础依赖 (git/curl/jq/bw/zsh/npm/tmux/htop/btop/nvtop)"
    ensure_cmd git
    ensure_cmd curl
    ensure_cmd jq
    ensure_cmd npm
    ensure_cmd bw bitwarden-cli
    ensure_cmd zsh
    ensure_cmd tmux
    ensure_cmd htop
    ensure_cmd btop
    ensure_cmd nvtop
}
