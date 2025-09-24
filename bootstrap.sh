#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# 模块化配置脚本
# ============================================================================

# --------- 配置区 ----------
DOTFILES_REPO="git@github.com:Erix025/dotfiles.git"
SSH_KEY_ITEM="GitHub SSH Key"
CLAUDE_API_KEY_ITEM="ZIPLab Claude API Key"
BW_SERVER="https://keys.erix025.me"
PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtBDeXHWjpQMX3bo80suNheGw5Q9W1TX3ty1csARYMQ eric025@IndexDev.local"
# ----------------------------

# 全局变量
SELECTED_MODULES=()
BW_SESSION=""

# 工具函数
check_homebrew() {
    if ! command -v brew &>/dev/null; then
        echo "⚠️ 请先安装 Homebrew: https://brew.sh/"
        exit 1
    fi
}

get_sudo() {
    if [[ $EUID -eq 0 ]]; then
        echo ""  # 如果是 root 用户，返回空字符串
    else
        echo "sudo"  # 如果不是 root 用户，返回 sudo
    fi
}

install_package() {
    local package_name="$1"
    local command_name="${2:-$1}"
    
    if command -v "$command_name" &>/dev/null; then
        echo "✅ $package_name 已安装"
        return 0
    fi
    
    echo "正在安装 $package_name..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        check_homebrew
        case "$package_name" in
            "zsh") brew install zsh ;;
            "bitwarden-cli") brew install bitwarden-cli ;;
            "tmux") brew install tmux ;;
            *) echo "⚠️ 未知包: $package_name"; exit 1 ;;
        esac
    elif [[ -f /etc/debian_version ]]; then
        local sudo_cmd=$(get_sudo)
        case "$package_name" in
            "zsh")
                $sudo_cmd apt update
                $sudo_cmd apt install -y zsh
                ;;
            "tmux")
                $sudo_cmd apt update
                $sudo_cmd apt install -y tmux
                ;;
            "bitwarden-cli")
                $sudo_cmd apt update
                $sudo_cmd apt install -y jq curl
                # 安装 nvm
                if ! command -v nvm &>/dev/null; then
                    echo "正在安装 nvm..."
                    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
                    export NVM_DIR="$HOME/.nvm"
                    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                    nvm install node
                    nvm use node
                fi
                npm install -g @bitwarden/cli
                ;;
        esac
    elif [[ -f /etc/redhat-release ]]; then
        local sudo_cmd=$(get_sudo)
        case "$package_name" in
            "zsh")
                $sudo_cmd dnf install -y zsh || $sudo_cmd yum install -y zsh
                ;;
            "tmux")
                $sudo_cmd dnf install -y tmux || $sudo_cmd yum install -y tmux
                ;;
            "bitwarden-cli")
                $sudo_cmd dnf install -y jq curl || $sudo_cmd yum install -y jq curl
                # 安装 nvm
                if ! command -v nvm &>/dev/null; then
                    echo "正在安装 nvm..."
                    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
                    export NVM_DIR="$HOME/.nvm"
                    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                    nvm install node
                    nvm use node
                fi
                npm install -g @bitwarden/cli
                ;;
        esac
    else
        echo "⚠️ 未知系统，请手动安装 $package_name"
        exit 1
    fi
    
    echo "✅ $package_name 安装完成"
}

install_python_tool() {
    local tool_name="$1"
    local install_script="$2"

    if command -v "$tool_name" &>/dev/null; then
        echo "✅ $tool_name 已安装"
        return 0
    fi

    echo "正在安装 $tool_name..."
    curl -LsSf "$install_script" | sh
    echo "✅ $tool_name 安装完成"
}

# ============================================================================
# 模块定义
# ============================================================================

set_default_shell() {
    local target_shell="$1"
    local current_shell=$(basename "$SHELL")

    if [[ "$current_shell" == "$target_shell" ]]; then
        echo "✅ 默认 shell 已经是 $target_shell"
        return 0
    fi

    # 查找 shell 路径
    local shell_path
    if command -v "$target_shell" &>/dev/null; then
        shell_path=$(command -v "$target_shell")
    else
        echo "⚠️ 找不到 $target_shell"
        return 1
    fi

    # 检查 shell 是否在 /etc/shells 中
    if ! grep -q "^$shell_path$" /etc/shells; then
        echo "正在将 $shell_path 添加到 /etc/shells..."
        local sudo_cmd=$(get_sudo)
        echo "$shell_path" | $sudo_cmd tee -a /etc/shells
    fi

    echo "正在将默认 shell 更改为 $target_shell..."
    local sudo_cmd=$(get_sudo)
    local current_user="${USER:-$(whoami)}"
    $sudo_cmd chsh -s "$shell_path" "$current_user"

    echo "✅ 默认 shell 已更改为 $target_shell"
    echo "ℹ️ 请重新登录或重启终端以生效"
}

module_basic_tools() {
    echo "=== 模块: 基础工具 (zsh, tmux) ==="
    install_package "zsh"
    install_package "tmux"
    set_default_shell "zsh"
}

module_bitwarden() {
    echo "=== 模块: Bitwarden CLI ==="
    install_package "bitwarden-cli" "bw"

    echo "正在配置 Bitwarden 服务器..."
    # 首先配置服务器，确保使用正确的服务器地址
    bw config server "$BW_SERVER"
    echo "✅ 服务器配置完成: $BW_SERVER"

    # 检查登录状态
    BW_STATUS=$(bw status)
    if echo "$BW_STATUS" | grep -q '"status":"unauthenticated"'; then
        echo "正在登录 Bitwarden..."
        bw login
    elif echo "$BW_STATUS" | grep -q '"status":"locked"'; then
        echo "✅ 已登录 Bitwarden，但需要解锁"
    else
        echo "✅ 已登录 Bitwarden"
    fi

    echo "正在解锁 Bitwarden..."
    BW_SESSION=$(bw unlock --raw)

    if [[ -z "$BW_SESSION" ]]; then
        echo "⚠️ 无法获取 Bitwarden 会话，请检查登录状态"
        exit 1
    fi
}

module_ssh() {
    echo "=== 模块: SSH 配置 ==="

    if [[ -z "$BW_SESSION" ]]; then
        echo "⚠️ 需要先执行 Bitwarden 模块"
        return 1
    fi

    echo "正在获取 SSH 私钥..."
    PRIVATE_KEY=$(bw get item "$SSH_KEY_ITEM" --session "$BW_SESSION" | jq -r '.sshKey.privateKey')

    if [[ -z "$PRIVATE_KEY" || "$PRIVATE_KEY" == "null" ]]; then
        echo "⚠️ 无法获取 SSH 私钥，请检查 Bitwarden 中的条目"
        return 1
    fi

    mkdir -p ~/.ssh
    echo "$PRIVATE_KEY" > ~/.ssh/github_key
    chmod 600 ~/.ssh/github_key

    # 备份现有配置
    if [[ -f ~/.ssh/config ]]; then
        cp ~/.ssh/config ~/.ssh/config.bak
        echo "✅ 已备份现有 SSH 配置到 ~/.ssh/config.bak"
    fi

    # 检查是否已存在 github.com 配置
    if [[ -f ~/.ssh/config ]] && grep -q "^Host github.com" ~/.ssh/config; then
        echo "⚠️ SSH 配置中已存在 github.com 配置，跳过添加"
    else
        # 在现有配置基础上追加新的 github.com 配置
        cat <<EOF >> ~/.ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_key
EOF
        echo "✅ 已添加 github.com SSH 配置"
    fi
    chmod 600 ~/.ssh/config

    echo "正在测试 SSH 连接..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "✅ SSH 连接测试成功"
    else
        echo "⚠️ SSH 连接测试失败，但继续执行"
    fi

    mkdir -p ~/.ssh
    if ! grep -q "$PUBLIC_KEY" ~/.ssh/authorized_keys 2>/dev/null; then
        echo "正在添加 SSH 公钥到 authorized_keys..."
        echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        echo "✅ SSH 公钥添加完成"
    else
        echo "✅ SSH 公钥已存在，跳过"
    fi
}

module_git() {
    echo "=== 模块: Git 配置 ==="
    echo "正在配置 Git..."

    git config --global user.name "Xi Lin"
    git config --global user.email "erix025@outlook.com"
    git config --global init.defaultBranch main

    echo "✅ Git 配置完成"
}

module_dotfiles() {
    echo "=== 模块: Dotfiles ==="
    if [[ ! -d ~/dotfiles ]]; then
        echo "正在克隆 dotfiles 仓库..."
        git clone "$DOTFILES_REPO" ~/dotfiles
        echo "✅ dotfiles 克隆完成"
    else
        echo "✅ dotfiles 已存在，更新到最新版本..."
        cd ~/dotfiles
        git pull origin main
        cd - > /dev/null
    fi

    echo "正在安装 dotfiles 配置..."
    if [[ -x ~/dotfiles/install.sh ]]; then
        ~/dotfiles/install.sh
        echo "✅ dotfiles 安装完成"
    else
        echo "⚠️ install.sh 不存在或不可执行"
        return 1
    fi
}

module_python_tools() {
    echo "=== 模块: Python 工具 (UV, Pixi) ==="
    install_python_tool "uv" "https://astral.sh/uv/install.sh"
    install_python_tool "pixi" "https://pixi.sh/install.sh"
}

module_claude() {
    echo "=== 模块: Claude CLI ==="

    if command -v claude &>/dev/null; then
        echo "✅ Claude CLI 已安装"
    else
        echo "正在安装 Claude CLI..."
        local sudo_cmd=$(get_sudo)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if ! command -v npm &>/dev/null; then
                check_homebrew
                echo "正在安装 Node.js..."
                brew install node
            fi
            npm install -g @anthropic-ai/claude-code
        else
            $sudo_cmd npm install -g @anthropic-ai/claude-code
        fi
        echo "✅ Claude CLI 安装完成"
    fi

    if [[ -z "$BW_SESSION" ]]; then
        echo "⚠️ 需要先执行 Bitwarden 模块以获取 API Key"
        return 1
    fi

    echo "正在从 Bitwarden 获取 Claude API Key..."
    CLAUDE_API_KEY=$(bw get item "$CLAUDE_API_KEY_ITEM" --session "$BW_SESSION" | jq -r '.login.password // .notes // .fields[]? | select(.name == "api_key" or .name == "API_KEY") | .value')

    if [[ -z "$CLAUDE_API_KEY" || "$CLAUDE_API_KEY" == "null" ]]; then
        echo "⚠️ 无法从 Bitwarden 获取 Claude API Key，请检查条目名称和字段"
        return 1
    else
        mkdir -p ~/.config
        echo "$CLAUDE_API_KEY" > ~/.config/claude_api_key
        chmod 600 ~/.config/claude_api_key
        echo "✅ Claude API Key 已保存到 ~/.config/claude_api_key"
    fi
}

module_vscode() {
    echo "=== 模块: VS Code Tunnel ==="

    mkdir -p ~/bin

    echo "正在下载 VS Code CLI..."
    if wget "https://code.visualstudio.com/sha/download?build=insider&os=cli-alpine-x64" -O vscode-cli.tar.gz; then
        echo "正在解压 VS Code CLI..."
        tar -xzf vscode-cli.tar.gz -C ~/bin
        rm vscode-cli.tar.gz

        if [[ -x ~/bin/code-insiders ]]; then
            echo "✅ VS Code tunnel 安装完成"
            echo "启动 VS Code tunnel..."
            ~/bin/code-insiders tunnel
        elif [[ -x ~/bin/code ]]; then
            echo "✅ VS Code tunnel 安装完成"
            echo "启动 VS Code tunnel..."
            ~/bin/code tunnel
        else
            echo "⚠️ 找不到 VS Code 可执行文件"
            return 1
        fi
    else
        echo "⚠️ 无法下载 VS Code tunnel，请检查网络连接"
        return 1
    fi
}

module_shell() {
    echo "=== 模块: Shell 环境配置 ==="

    # 检查是否已通过 dotfiles 安装了 .zshrc
    if [[ -L ~/.zshrc ]] && [[ -f ~/dotfiles/zsh/.zshrc ]]; then
        echo "✅ .zshrc 已通过 dotfiles 链接安装"
    elif [[ -f ~/dotfiles/zsh/.zshrc ]]; then
        echo "⚠️ 检测到 dotfiles 中的 .zshrc，但未正确链接"
        echo "建议先运行 dotfiles 模块以正确安装配置文件"
    else
        echo "正在创建基本的 .zshrc 配置..."
        cat <<EOF > ~/.zshrc
# Basic zsh configuration

# Claude API Key configuration
if [[ -f ~/.config/claude_api_key ]]; then
    export ANTHROPIC_API_KEY=\$(cat ~/.config/claude_api_key)
fi
EOF
        echo "✅ 已创建基本的 .zshrc 配置"
    fi
}

# ============================================================================
# 预设模板
# ============================================================================

template_basic() {
    SELECTED_MODULES=("basic_tools" "git" "shell")
}

template_development() {
    SELECTED_MODULES=("basic_tools" "bitwarden" "ssh" "git" "dotfiles" "python_tools" "claude" "shell")
}

template_server() {
    SELECTED_MODULES=("basic_tools" "bitwarden" "ssh" "git" "shell")
}

template_full() {
    SELECTED_MODULES=("basic_tools" "bitwarden" "ssh" "git" "dotfiles" "python_tools" "claude" "vscode" "shell")
}

# ============================================================================
# 交互式菜单
# ============================================================================

show_main_menu() {
    echo ""
    echo "============================================================================"
    echo "                           模块化配置脚本"
    echo "============================================================================"
    echo ""
    echo "请选择配置模式："
    echo ""
    echo "  预设模板:"
    echo "    1) 基础配置    - 基础工具 + Git + Shell"
    echo "    2) 开发环境    - 基础 + SSH + Python工具 + Claude + Dotfiles"
    echo "    3) 服务器配置  - 基础 + SSH + Git + Shell"
    echo "    4) 完整配置    - 所有模块"
    echo ""
    echo "  自定义:"
    echo "    5) 自定义选择  - 手动选择模块"
    echo "    6) 查看所有模块"
    echo ""
    echo "    0) 退出"
    echo ""
    echo "============================================================================"
    echo -n "请选择 [0-6]: "
}

show_modules_menu() {
    echo ""
    echo "============================================================================"
    echo "                              可用模块"
    echo "============================================================================"
    echo ""
    echo "  1) basic_tools    - 基础工具 (zsh, tmux)"
    echo "  2) bitwarden      - Bitwarden CLI 和认证"
    echo "  3) ssh            - SSH 密钥配置"
    echo "  4) git            - Git 配置"
    echo "  5) dotfiles       - Dotfiles 仓库克隆"
    echo "  6) python_tools   - Python 工具 (UV, Pixi)"
    echo "  7) claude         - Claude CLI"
    echo "  8) vscode         - VS Code Tunnel"
    echo "  9) shell          - Shell 环境配置"
    echo ""
    echo "  a) 全选          s) 开始执行"
    echo "  c) 清空选择      b) 返回主菜单"
    echo ""
    echo "============================================================================"
    echo "当前已选择: ${SELECTED_MODULES[*]}"
    echo ""
    echo -n "请选择模块 [1-9,a,s,c,b]: "
}

custom_selection() {
    SELECTED_MODULES=()

    while true; do
        show_modules_menu
        read -r choice

        case $choice in
            1) toggle_module "basic_tools" ;;
            2) toggle_module "bitwarden" ;;
            3) toggle_module "ssh" ;;
            4) toggle_module "git" ;;
            5) toggle_module "dotfiles" ;;
            6) toggle_module "python_tools" ;;
            7) toggle_module "claude" ;;
            8) toggle_module "vscode" ;;
            9) toggle_module "shell" ;;
            a|A) SELECTED_MODULES=("basic_tools" "bitwarden" "ssh" "git" "dotfiles" "python_tools" "claude" "vscode" "shell") ;;
            c|C) SELECTED_MODULES=() ;;
            s|S)
                if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
                    echo "⚠️ 请至少选择一个模块"
                    sleep 2
                else
                    break
                fi
                ;;
            b|B) return 1 ;;
            *) echo "⚠️ 无效选择"; sleep 1 ;;
        esac
    done
}

toggle_module() {
    local module="$1"
    local found=false
    local new_array=()

    for selected in "${SELECTED_MODULES[@]}"; do
        if [[ "$selected" == "$module" ]]; then
            found=true
        else
            new_array+=("$selected")
        fi
    done

    if [[ "$found" == "false" ]]; then
        new_array+=("$module")
    fi

    SELECTED_MODULES=("${new_array[@]}")
}

# ============================================================================
# 执行函数
# ============================================================================

execute_modules() {
    echo ""
    echo "============================================================================"
    echo "开始执行选定的模块..."
    echo "============================================================================"
    echo ""
    echo "将要执行的模块: ${SELECTED_MODULES[*]}"
    echo ""
    echo -n "确认执行? [y/N]: "
    read -r confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "已取消执行"
        return 1
    fi

    echo ""
    echo "开始执行..."
    echo ""

    for module in "${SELECTED_MODULES[@]}"; do
        echo ""
        echo "执行模块: $module"
        echo "----------------------------------------"

        case $module in
            "basic_tools") module_basic_tools ;;
            "bitwarden") module_bitwarden ;;
            "ssh") module_ssh ;;
            "git") module_git ;;
            "dotfiles") module_dotfiles ;;
            "python_tools") module_python_tools ;;
            "claude") module_claude ;;
            "vscode") module_vscode ;;
            "shell") module_shell ;;
            *) echo "⚠️ 未知模块: $module" ;;
        esac

        echo "✅ 模块 $module 执行完成"
    done

    echo ""
    echo "🎉 所有选定模块执行完成！"
}

# ============================================================================
# 主程序
# ============================================================================

main() {
    while true; do
        show_main_menu
        read -r choice

        case $choice in
            1) template_basic; execute_modules ;;
            2) template_development; execute_modules ;;
            3) template_server; execute_modules ;;
            4) template_full; execute_modules ;;
            5)
                if custom_selection; then
                    execute_modules
                fi
                ;;
            6)
                show_modules_menu
                echo ""
                echo -n "按回车键返回主菜单..."
                read -r
                ;;
            0) echo "退出脚本"; exit 0 ;;
            *) echo "⚠️ 无效选择"; sleep 1 ;;
        esac
    done
}

# 检查是否以交互模式运行
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  --basic        执行基础配置"
    echo "  --dev          执行开发环境配置"
    echo "  --server       执行服务器配置"
    echo "  --full         执行完整配置"
    echo ""
    echo "不带参数运行将进入交互模式"
    exit 0
elif [[ "${1:-}" == "--basic" ]]; then
    template_basic
    execute_modules
elif [[ "${1:-}" == "--dev" ]]; then
    template_development
    execute_modules
elif [[ "${1:-}" == "--server" ]]; then
    template_server
    execute_modules
elif [[ "${1:-}" == "--full" ]]; then
    template_full
    execute_modules
else
    main
fi