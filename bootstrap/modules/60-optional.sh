#!/usr/bin/env bash

module_optional() {
    log "执行可选模块 (uv/pixi/Claude CLI/VS Code CLI)"

    install_python_tool "uv" "https://astral.sh/uv/install.sh"
    install_python_tool "pixi" "https://pixi.sh/install.sh"

    install_claude_cli
    install_vscode_cli
}

install_claude_cli() {
    if command -v claude >/dev/null 2>&1; then
        return
    fi

    if ! command -v npm >/dev/null 2>&1; then
        warn "缺少 npm，无法安装 Claude CLI"
        return
    fi

    log "安装 Claude CLI"
    npm install -g @anthropic-ai/claude-code
}

install_vscode_cli() {
    local bin_dir="$HOME/bin"
    ensure_dir "$bin_dir"

    if [[ -x "$bin_dir/code" || -x "$bin_dir/code-insiders" ]]; then
        log "VS Code CLI 已安装"
        return
    fi

    local tmp
    tmp=$(mktemp)
    curl -fsSL "https://code.visualstudio.com/sha/download?build=insider&os=cli-alpine-x64" -o "$tmp"
    tar -xzf "$tmp" -C "$bin_dir"
    rm -f "$tmp"
    log "VS Code CLI 已安装，可使用 code tunnel 手动启动"
}
