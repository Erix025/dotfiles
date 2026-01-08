# Shared helpers for tmux runner commands
_tmux_runner_require() {
  local cmd_name="$1"
  if ! command -v tmux >/dev/null 2>&1; then
    echo "${cmd_name}: tmux not found"
    return 127
  fi
}

_tmux_runner_session() {
  local s
  s="$(basename "$PWD")"
  print -r -- "${s//[^A-Za-z0-9._-]/_}"
}

_tmux_runner_winname() {
  local ts gpu head cmd
  ts="$(date +%H%M%S)"
  cmd="$*"
  gpu="$(print -r -- "$cmd" | sed -nE 's/.*CUDA_VISIBLE_DEVICES=([^ ]+).*/\1/p' | head -n1)"
  head="$(print -r -- "$cmd" | sed -E 's/[[:space:]]+/ /g' | cut -c1-28)"
  if [[ -n "$gpu" ]]; then
    print -r -- "${ts}-gpu${gpu}-${head}"
  else
    print -r -- "${ts}-${head}"
  fi
}

_tmux_runner_create_window() {
  local session="$1"; shift
  local winname="$1"; shift
  local cmd_display
  printf -v cmd_display '%q ' "$@"
  cmd_display="${cmd_display% }"
  local payload
  payload="set -e; echo \"▶ $cmd_display\"; eval $cmd_display; ec=\$?; echo; echo \"✓ done (exit=\$ec)\"; exit \$ec"
  tmux new-window -t "$session" -n "$winname" "zsh -lc $(printf %q "$payload")"
}
