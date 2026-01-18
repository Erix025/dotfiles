# ezsh ssh - Bitwarden-backed ssh-agent workflow

ezsh_desc_ssh="Manage SSH keys via Bitwarden + ssh-agent (no disk writes)"

ezsh_cmd_ssh() {
  emulate -L zsh
  setopt localoptions no_unset

  local cmd="${1:-help}"
  shift $(( $# > 0 ? 1 : 0 ))

  case "$cmd" in
    unlock|--unlock)
      _ezsh_ssh_unlock "$@"
      ;;
    list|--list)
      _ezsh_ssh_list
      ;;
    remove|--remove)
      _ezsh_ssh_remove
      ;;
    test|--test)
      _ezsh_ssh_test
      ;;
    help|--help|-h|'')
      _ezsh_ssh_usage
      ;;
    *)
      print -ru2 -- "[ezsh][ssh] Unknown subcommand: $cmd"
      _ezsh_ssh_usage
      return 1
      ;;
  esac
}

_ezsh_ssh_usage() {
  cat <<'EOF'
Usage: ezsh ssh <subcommand>

Subcommands:
  unlock [--ttl <seconds>]   Load GitHub key from Bitwarden into ssh-agent (no files)
  list                       Show identities currently held by ssh-agent
  remove                     Remove the GitHub key from ssh-agent
  test                       Run ssh -T git@github.com to verify auth
  help                       Show this help

Flags:
  --ttl <seconds>   Set lifetime when ssh-add supports -t

Examples:
  ezsh ssh unlock --ttl 3600
  ezsh ssh test
EOF
}

_ezsh_ssh_bootstrap_dir_default() {
  if [[ -n "${EZSH_BOOTSTRAP_DIR:-}" ]]; then
    printf '%s' "$EZSH_BOOTSTRAP_DIR"
  else
    printf '%s' "$HOME/dotfiles/bootstrap"
  fi
}

_ezsh_ssh_load_config() {
  if [[ -n "${_EZSH_SSH_CFG_LOADED:-}" ]]; then
    return 0
  fi

  local bootstrap_dir
  bootstrap_dir="$(_ezsh_ssh_bootstrap_dir_default)"

  local cfg="$bootstrap_dir/config.sh"
  if [[ -r "$cfg" ]]; then
    source "$cfg"
  else
    : "${DOTFILES_DIR:=$HOME/dotfiles}"
    : "${BW_SERVER:=https://keys.erix025.me}"
    : "${SSH_KEY_ITEM:=GitHub SSH Key}"
  fi

  : "${DOTFILES_DIR:=$HOME/dotfiles}"
  : "${BW_SERVER:=https://keys.erix025.me}"
  : "${SSH_KEY_ITEM:=GitHub SSH Key}"

  _EZSH_SSH_CFG_LOADED=1
}

_ezsh_ssh_require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    print -ru2 -- "[ezsh][ssh] Missing required command: $cmd"
    return 1
  fi
}

_ezsh_ssh_init() {
  _ezsh_ssh_load_config || return 1
  _ezsh_ssh_require_cmd bw || return 1
  _ezsh_ssh_require_cmd jq || return 1
  _ezsh_ssh_require_cmd ssh-add || return 1
  _ezsh_ssh_require_cmd ssh-agent || return 1
  _ezsh_ssh_require_cmd ssh || return 1
}

_ezsh_ssh_agent_ready() {
  [[ -S "${SSH_AUTH_SOCK:-}" ]] || return 1

  local output rc
  output=$(ssh-add -l 2>&1)
  rc=$?

  if (( rc == 0 )); then
    return 0
  fi

  if (( rc == 1 )) && [[ "$output" == *"The agent has no identities."* ]]; then
    return 0
  fi

  return 1
}

_ezsh_ssh_macos_launchctl_sock() {
  if command -v launchctl >/dev/null 2>&1; then
    launchctl getenv SSH_AUTH_SOCK 2>/dev/null
  fi
}

_ezsh_ssh_ensure_agent() {
  if _ezsh_ssh_agent_ready; then
    return 0
  fi

  if [[ "$OSTYPE" == darwin* ]]; then
    local sock
    sock="$(_ezsh_ssh_macos_launchctl_sock)"
    if [[ -n "$sock" ]]; then
      export SSH_AUTH_SOCK="$sock"
      if _ezsh_ssh_agent_ready; then
        return 0
      fi
    fi
  fi

  eval "$(ssh-agent -s)" >/dev/null
  if _ezsh_ssh_agent_ready; then
    return 0
  fi

  print -ru2 -- "[ezsh][ssh] ssh-agent unavailable"
  return 1
}

_ezsh_ssh_require_bw_session() {
  _ezsh_ssh_require_cmd bw || return 1
  _ezsh_ssh_require_cmd jq || return 1

  local bw_status=""
  bw_status=$(bw status 2>/dev/null || true)

  if [[ -n "${BW_SERVER:-}" ]]; then
    local current_server=""
    local session_state=""
    if [[ -n "$bw_status" ]]; then
      current_server=$(print -r -- "$bw_status" | jq -r '.serverUrl // empty' 2>/dev/null || true)
      session_state=$(print -r -- "$bw_status" | jq -r '.status // empty' 2>/dev/null || true)
    fi

    if [[ "$current_server" != "$BW_SERVER" ]]; then
      if [[ "$session_state" == "unlocked" || "$session_state" == "locked" ]]; then
        print -ru2 -- "[ezsh][ssh] Bitwarden 已登录 (status: $session_state)，跳过 server 切换 (当前: ${current_server:-<未配置>}，目标: $BW_SERVER)"
        print -ru2 -- "[ezsh][ssh] 如需切换服务器请运行: bw logout && bw config server \"$BW_SERVER\""
      else
        print -ru2 -- "[ezsh][ssh] 配置 Bitwarden 服务器: $BW_SERVER"
        bw config server "$BW_SERVER" >/dev/null
        bw_status=""
      fi
    fi
  fi

  if [[ -n "${BW_SESSION:-}" ]]; then
    return 0
  fi

  if [[ -z "$bw_status" ]]; then
    bw_status=$(bw status 2>/dev/null || true)
  fi

  if echo "$bw_status" | grep -q '"status":"unauthenticated"'; then
    print -ru2 -- "[ezsh][ssh] Bitwarden 未登录，执行 bw login..."
    bw login || return 1
    bw_status=$(bw status 2>/dev/null || true)
  fi

  if echo "$bw_status" | grep -q '"status":"unlocked"'; then
    bw lock >/dev/null 2>&1 || true
  fi

  print -ru2 -- "[ezsh][ssh] 正在解锁 Bitwarden..."
  BW_SESSION=$(bw unlock --raw) || return 1
  export BW_SESSION
}

_ezsh_ssh_fetch_private_key() {
  _ezsh_ssh_require_bw_session || return 1

  local item="${SSH_KEY_ITEM}"
  local raw=""
  local attempt=0
  while (( attempt < 2 )); do
    if raw=$(bw get item "$item" --session "$BW_SESSION" 2>/dev/null); then
      break
    fi
    (( attempt++ ))
    if (( attempt >= 2 )); then
      print -ru2 -- "[ezsh][ssh] 获取 Bitwarden 条目失败：$item"
      return 1
    fi
    print -ru2 -- "[ezsh][ssh] Bitwarden 会话失效，重新解锁..."
    unset BW_SESSION
    _ezsh_ssh_require_bw_session || return 1
  done

  local key pub
  key=$(print -r -- "$raw" | jq -r '.sshKey.privateKey // empty')
  if [[ -z "$key" || "$key" == "null" ]]; then
    print -ru2 -- "[ezsh][ssh] 条目 $item 缺少 sshKey.privateKey"
    return 1
  fi

  pub=$(print -r -- "$raw" | jq -r '.sshKey.publicKey // empty')
  if [[ "$pub" == "null" ]]; then
    pub=""
  fi

  # Normalize line endings for ssh-add to avoid "invalid format".
  key="${key//$'\r'/}"
  pub="${pub//$'\r'/}"

  if [[ -n "$pub" ]]; then
    typeset -g _EZSH_SSH_PUBLIC_KEY="$pub"
  else
    unset _EZSH_SSH_PUBLIC_KEY
  fi

  print -r -- "$key"
}

_ezsh_ssh_supports_ttl() {
  ssh-add -h 2>&1 | grep -q -- '-t lifetime'
}

_ezsh_ssh_public_key() {
  if [[ -n "${_EZSH_SSH_PUBLIC_KEY:-}" ]]; then
    print -r -- "$_EZSH_SSH_PUBLIC_KEY"
    return 0
  fi

  print -ru2 -- "[ezsh][ssh] Bitwarden 条目缺少 sshKey.publicKey，无法执行该操作"
  print -ru2 -- "[ezsh][ssh] 请在 Bitwarden 条目中填写公钥字段 (通常以 ssh-ed25519/ssh-rsa 开头)"
  return 1
}

_ezsh_ssh_add_key() {
    local key="$1"
    local ttl="$2"

    local ttl_args=()
    if [[ -n "$ttl" ]]; then
        if _ezsh_ssh_supports_ttl; then
            ttl_args=(-t "$ttl")
        else
            print -ru2 -- "[ezsh][ssh] 当前 ssh-add 不支持 --ttl，已忽略"
        fi
    fi

    # 关键：用 stdin 喂给 ssh-add，避免 FIFO 在部分平台导致 invalid format
    if print -r -- "$key" | ssh-add "${ttl_args[@]}" - >/dev/null; then
        return 0
    fi

    print -ru2 -- "[ezsh][ssh] ssh-add 加载密钥失败（stdin 模式）"
    return 1
}

_ezsh_ssh_state_file() {
    local dir="${EZSH_STATE_DIR:-$HOME/.config/ezsh}"
    mkdir -p "$dir"
    printf '%s/ssh-agent.fingerprint' "$dir"
}

_ezsh_ssh_store_fingerprint() {
    local pub="${_EZSH_SSH_PUBLIC_KEY:-}"
    if [[ -z "$pub" ]]; then
        return 0
  fi

  local meta
  meta=$(printf '%s\n' "$pub" | ssh-keygen -lf /dev/stdin 2>/dev/null) || return 0
  local file
  file="$(_ezsh_ssh_state_file)"
  print -r -- "$meta" >| "$file"
}

_ezsh_ssh_clear_fingerprint() {
  local file="$(_ezsh_ssh_state_file)"
  rm -f "$file"
}

_ezsh_ssh_unlock() {
  emulate -L zsh
  setopt localoptions no_unset

  local ttl=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ttl)
        if [[ -z "${2:-}" ]]; then
          print -ru2 -- "[ezsh][ssh] --ttl 需要秒数"
          return 1
        fi
        ttl="$2"
        shift 2
        ;;
      *)
        print -ru2 -- "[ezsh][ssh] 未知参数: $1"
        return 1
        ;;
    esac
  done

  _ezsh_ssh_init || return 1
  _ezsh_ssh_ensure_agent || return 1

    local key
    key="$(_ezsh_ssh_fetch_private_key)" || return 1
    if _ezsh_ssh_add_key "$key" "$ttl"; then
    print -ru2 -- "[ezsh][ssh] GitHub 密钥已加载到 ssh-agent"
    _ezsh_ssh_store_fingerprint
    _ezsh_ssh_list
  else
    return 1
  fi
}

_ezsh_ssh_list() {
  _ezsh_ssh_init || return 1
  if ! _ezsh_ssh_agent_ready; then
    if ! _ezsh_ssh_ensure_agent; then
      return 1
    fi
  fi

  ssh-add -l
}

_ezsh_ssh_remove() {
  _ezsh_ssh_init || return 1
  _ezsh_ssh_ensure_agent || return 1

  local key pub
  key="$(_ezsh_ssh_fetch_private_key)" || return 1

  pub="$(_ezsh_ssh_public_key)" || return 1

  if printf '%s\n' "$pub" | ssh-add -d - >/dev/null 2>&1; then
    print -ru2 -- "[ezsh][ssh] 已从 ssh-agent 删除 GitHub 密钥"
    _ezsh_ssh_clear_fingerprint
    return 0
  fi

  print -ru2 -- "[ezsh][ssh] 无法定位密钥，请手动运行: ssh-add -D"
  return 1
}

_ezsh_ssh_test() {
  _ezsh_ssh_init || return 1
  _ezsh_ssh_ensure_agent || return 1

  local output
  output=$(ssh -T git@github.com 2>&1)
  local rc=$?

  print -r -- "$output"

  if [[ "$output" == *"successfully authenticated"* || "$output" == *"Hi "* ]]; then
    print -ru2 -- "[ezsh][ssh] GitHub 认证成功"
    return 0
  fi

  print -ru2 -- "[ezsh][ssh] GitHub 认证失败"
  return $rc
}
