_ezsh_tmux_require_helpers_tkill() {
  if [[ -n ${_EZSH_TMUX_COMMON_LOADED:-} ]]; then
    return 0
  fi
  local helper="${EZSH_COMMANDS_DIR}/tmux-common.inc"
  if [[ ! -r "$helper" ]]; then
    echo "tkill: missing tmux helpers ($helper)"
    return 1
  fi
  source "$helper"
  _EZSH_TMUX_COMMON_LOADED=1
}

ezsh_desc_tkill="Kill tmux session"
ezsh_cmd_tkill() {
  _ezsh_tmux_require_helpers_tkill || return $?
  _tmux_runner_require tkill || return $?
  local session="${1:-$(_tmux_runner_session)}"
  if tmux kill-session -t "$session" 2>/dev/null; then
    echo "tkill: killed '$session'"
  else
    echo "tkill: no such session: $session"
    return 1
  fi
}
