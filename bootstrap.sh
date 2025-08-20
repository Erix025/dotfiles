#!/usr/bin/env bash
set -euo pipefail

# --------- 配置区 ----------
DOTFILES_REPO="git@github.com:Erix025/dotfiles.git"
SSH_KEY_ITEM="GitHub SSH Key"   # 你在 Bitwarden 里存放 SSH key 的条目名
BW_SERVER="https://keys.erix025.me"
# ----------------------------

echo "=== Step 0: 安装 Bitwarden CLI ==="
if ! command -v bw &>/dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS: 使用 Homebrew 安装 bw"
        if ! command -v brew &>/dev/null; then
            echo "请先安装 Homebrew: https://brew.sh/"
            exit 1
        fi
        brew install bitwarden-cli
    elif [[ -f /etc/debian_version ]]; then
        echo "Debian/Ubuntu: 使用 npm 安装 bw"
        sudo apt update
        sudo apt install -y npm jq
        sudo npm install -g @bitwarden/cli
    elif [[ -f /etc/redhat-release ]]; then
        echo "RHEL/CentOS/Fedora: 使用 npm 安装 bw"
        sudo dnf install -y npm jq || sudo yum install -y npm jq
        sudo npm install -g @bitwarden/cli
    else
        echo "⚠️ 未知系统，请手动安装 Bitwarden CLI"
        exit 1
    fi
else
    echo "✅ Bitwarden CLI 已安装"
fi

echo "=== Step 1: 启动 Bitwarden SSH Agent ==="

export SSH_AUTH_SOCK=~/.bitwarden-ssh-agent.sock

echo "=== Step 2: 登录 Bitwarden ==="
if ! bw status | grep -q '"status":"unauthenticated"'; then
    echo "已登录 Bitwarden"
else
    bw login
fi

echo "=== Step 4: 测试 SSH 连接 ==="
ssh-add -L || true
ssh -T git@github.com || true

echo "=== Step 5: 克隆 dotfiles ==="
if [[ ! -d ~/dotfiles ]]; then
    git clone "$DOTFILES_REPO" ~/dotfiles
else
    echo "dotfiles 已存在，跳过"
fi

echo "=== Step 6: 安装 UV 和 Pixi ==="
if ! command -v uv &>/dev/null; then
    echo "安装 UV"
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    echo "✅ UV 已安装"
fi

if ! command -v pixi &>/dev/null; then
    echo "安装 Pixi"
    curl -fsSL https://pixi.sh/install.sh | sh
else
    echo "✅ Pixi 已安装"
fi

echo "=== Step 7: 设置 SSH Authorized Keys ==="

PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtBDeXHWjpQMX3bo80suNheGw5Q9W1TX3ty1csARYMQ eric025@IndexDev.local"
if ! grep -q "$PUBLIC_KEY" ~/.ssh/authorized_keys; then
    echo "添加 SSH 公钥到 authorized_keys"
    echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
else
    echo "SSH 公钥已存在，跳过"
fi

echo "✅ 全部完成！"