#!/usr/bin/env bash

: "${DOTFILES_REPO:=https://github.com/Erix025/dotfiles.git}"
: "${DOTFILES_DIR:=$HOME/dotfiles}"
: "${BW_SERVER:=https://keys.erix025.me}"
: "${SSH_KEY_ITEM:=GitHub SSH Key}"

export DOTFILES_REPO
export DOTFILES_DIR
export BW_SERVER
export SSH_KEY_ITEM
