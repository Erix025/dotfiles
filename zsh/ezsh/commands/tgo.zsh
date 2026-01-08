_ezsh_tmux_require_helpers_tgo() {
  if [[ -n ${_EZSH_TMUX_COMMON_LOADED:-} ]]; then
    return 0
  fi
  local helper="${EZSH_COMMANDS_DIR}/tmux-common.inc"
  if [[ ! -r "$helper" ]]; then
    echo "tgo: missing tmux helpers ($helper)"
    return 1
  fi
  source "$helper"
  _EZSH_TMUX_COMMON_LOADED=1
}

ezsh_desc_tgo="Attach/switch to tmux session"
ezsh_cmd_tgo() {
  _ezsh_tmux_require_helpers_tgo || return $?
  _tmux_runner_require tgo || return $?
  local session="${1:-$(_tmux_runner_session)}"
  if tmux has-session -t "$session" 2>/dev/null; then
    if [[ -n "${TMUX:-}" ]]; then
      tmux switch-client -t "$session"
    else
      tmux attach -t "$session"
    fi
  else
    echo "tgo: no such session: $session"
    return 1
  fi
}
