#!/usr/bin/env bash
set -euo pipefail

# --------- 配置区 ----------
DOTFILES_REPO="git@github.com:Erix025/dotfiles.git"
SSH_KEY_ITEM="GitHub SSH Key"   # 你在 Bitwarden 里存放 SSH key 的条目名
BW_SERVER="https://keys.erix025.me"
PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtBDeXHWjpQMX3bo80suNheGw5Q9W1TX3ty1csARYMQ eric025@IndexDev.local"
# ----------------------------

# 工具函数
check_homebrew() {
    if ! command -v brew &>/dev/null; then
        echo "⚠️ 请先安装 Homebrew: https://brew.sh/"
        exit 1
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
            *) echo "⚠️ 未知包: $package_name"; exit 1 ;;
        esac
    elif [[ -f /etc/debian_version ]]; then
        case "$package_name" in
            "zsh")
                sudo apt update
                sudo apt install -y zsh
                ;;
            "bitwarden-cli")
                sudo apt update
                sudo apt install -y jq curl
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
        case "$package_name" in
            "zsh")
                sudo dnf install -y zsh || sudo yum install -y zsh
                ;;
            "bitwarden-cli")
                sudo dnf install -y jq curl || sudo yum install -y jq curl
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

echo "=== Step 1: 安装 zsh ==="
install_package "zsh"

echo "=== Step 2: 安装 Bitwarden CLI ==="
install_package "bitwarden-cli" "bw"

echo "=== Step 3: 登录 Bitwarden ==="

bw config server "$BW_SERVER"

if bw status | grep -q '"status":"unauthenticated"'; then
    echo "正在登录 Bitwarden..."
    bw login
else
    echo "✅ 已登录 Bitwarden"
fi

echo "=== Step 4: 配置 SSH Key ==="

echo "正在解锁 Bitwarden..."
BW_SESSION=$(bw unlock --raw)

if [[ -z "$BW_SESSION" ]]; then
    echo "⚠️ 无法获取 Bitwarden 会话，请检查登录状态"
    exit 1
fi

echo "正在获取 SSH 私钥..."
PRIVATE_KEY=$(bw get item "$SSH_KEY_ITEM" --session "$BW_SESSION" | jq -r '.sshKey.privateKey')

if [[ -z "$PRIVATE_KEY" || "$PRIVATE_KEY" == "null" ]]; then
    echo "⚠️ 无法获取 SSH 私钥，请检查 Bitwarden 中的条目"
    exit 1
fi

mkdir -p ~/.ssh
echo "$PRIVATE_KEY" > ~/.ssh/github_key
chmod 600 ~/.ssh/github_key

# 备份现有的 SSH 配置
if [[ -f ~/.ssh/config ]]; then
    cp ~/.ssh/config ~/.ssh/config.bak
fi

cat <<EOF > ~/.ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_key
EOF
chmod 600 ~/.ssh/config

echo "=== Step 5: 测试 SSH 连接 ==="
echo "正在测试 SSH 连接..."
ssh-add -L || true
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH 连接测试成功"
else
    echo "⚠️ SSH 连接测试失败，但继续执行"
fi

echo "=== Step 6: 克隆 dotfiles ==="
if [[ ! -d ~/dotfiles ]]; then
    echo "正在克隆 dotfiles 仓库..."
    git clone "$DOTFILES_REPO" ~/dotfiles
    echo "✅ dotfiles 克隆完成"
else
    echo "✅ dotfiles 已存在，跳过"
fi

echo "=== Step 7: 安装 UV 和 Pixi ==="
install_python_tool "uv" "https://astral.sh/uv/install.sh"
install_python_tool "pixi" "https://pixi.sh/install.sh"

echo "=== Step 8: 设置 SSH Authorized Keys ==="

mkdir -p ~/.ssh
if ! grep -q "$PUBLIC_KEY" ~/.ssh/authorized_keys 2>/dev/null; then
    echo "正在添加 SSH 公钥到 authorized_keys..."
    echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    echo "✅ SSH 公钥添加完成"
else
    echo "✅ SSH 公钥已存在，跳过"
fi

echo "=== Step 9: 设置 VS Code Tunnel ==="

# 确保 ~/bin 目录存在
mkdir -p ~/bin

echo "正在下载 VS Code CLI..."
if wget "https://code.visualstudio.com/sha/download?build=insider&os=cli-alpine-x64" -O vscode-cli.tar.gz; then
    echo "正在解压 VS Code CLI..."
    tar -xzf vscode-cli.tar.gz -C ~/bin
    rm vscode-cli.tar.gz
    
    # 确保可执行文件路径正确
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
        exit 1
    fi
else
    echo "⚠️ 无法下载 VS Code tunnel，请检查网络连接"
    exit 1
fi

echo "🎉 全部完成！"