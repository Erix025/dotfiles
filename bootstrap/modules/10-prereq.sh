#!/usr/bin/env bash

module_prereq() {
    log "安装基础依赖 (git/curl/jq/bw/zsh)"
    ensure_cmd git
    ensure_cmd curl
    ensure_cmd jq
    ensure_cmd bw bitwarden-cli
    ensure_cmd zsh
}
