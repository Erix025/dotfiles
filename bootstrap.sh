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

echo "✅ 全部完成！"
echo "请确保 SSH_AUTH_SOCK 已设置，可以使用 ssh 命令访问 GitHub"