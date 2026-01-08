_ezsh_tmux_require_helpers_trun() {
  if [[ -n ${_EZSH_TMUX_COMMON_LOADED:-} ]]; then
    return 0
  fi
  local helper="${EZSH_COMMANDS_DIR}/tmux-common.inc"
  if [[ ! -r "$helper" ]]; then
    echo "trun: missing tmux helpers ($helper)"
    return 1
  fi
  source "$helper"
  _EZSH_TMUX_COMMON_LOADED=1
}

ezsh_desc_trun="Run command in per-dir tmux session"
ezsh_cmd_trun() {
  _ezsh_tmux_require_helpers_trun || return $?

  if (( $# == 0 )); then
    echo "Usage: trun <command...>"
    return 2
  fi

  _tmux_runner_require trun || return $?

  local session="$(_tmux_runner_session)"
  local winname="$(_tmux_runner_winname "$@")"

  tmux has-session -t "$session" 2>/dev/null || tmux new-session -d -s "$session" -n "shell"
  _tmux_runner_create_window "$session" "$winname" "$@"

  echo "trun: started in tmux session '$session' window '$winname'"
  echo "      view: tgo  |  list: tmux ls  |  windows: tmux lsw -t '$session'"
}
