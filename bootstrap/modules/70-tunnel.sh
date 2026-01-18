#!/usr/bin/env bash

module_tunnel() {
    log "安装 VS Code Tunnel"

    install_vscode_cli

    local code_cmd=""
    if command -v code >/dev/null 2>&1; then
        code_cmd="$(command -v code)"
    elif command -v code-insiders >/dev/null 2>&1; then
        code_cmd="$(command -v code-insiders)"
    else
        warn "未找到 VS Code CLI (code/code-insiders)"
        return 1
    fi

    if "$code_cmd" tunnel service status >/dev/null 2>&1; then
        log "VS Code Tunnel 服务已安装"
        return 0
    fi

    if "$code_cmd" tunnel service install --accept-server-license-terms; then
        log "VS Code Tunnel 服务安装完成，可使用 'code tunnel service log' 查看状态"
    else
        warn "VS Code Tunnel 服务安装失败，请手动运行: $code_cmd tunnel service install --accept-server-license-terms"
        return 1
    fi
}
