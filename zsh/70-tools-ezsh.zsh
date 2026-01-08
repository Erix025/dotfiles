log_cmd() {
  # Usage: log_cmd "Backup" cp ~/.zshrc ~/.zshrc.old
  local msg="$1"; shift

  local bold=$'\033[1m'
  local reset=$'\033[0m'
  local red=$'\033[31m'
  local blue=$'\033[34m'
  local magenta=$'\033[35m'
  local cyan=$'\033[36m'

  local cmd_str=""
  for arg in "$@"; do
    cmd_str+="${(q)arg} "
  done

  echo -e "${bold}${blue}[${magenta}${msg}${blue}]${reset} ${cyan}${cmd_str}${reset}"

  "$@"
  local st=$?
  if [[ $st -ne 0 ]]; then
    echo -e "${bold}${red}[Error]${reset} status=${st}"
  fi
  return $st
}
# -------------------------
# ezsh core (zsh-only, safe)
# -------------------------

# Where your custom command files live
: "${EZSH_COMMANDS_DIR:=${HOME}/dotfiles/zsh/ezsh/commands}"

# Print usage
_ezsh_usage() {
  print -r -- "Usage: ezsh <command> [args...]"
  print -r -- "Custom commands from: ${EZSH_COMMANDS_DIR}/*.zsh"
  print -r -- ""
  print -r -- "Commands:"
  print -r -- "  help"
  print -r -- "  list"
}

# List command names (one per line). No fancy substitutions.
_ezsh_list_cmds() {
  emulate -L zsh
  setopt localoptions null_glob

  local f name
  for f in "${EZSH_COMMANDS_DIR}"/*.zsh; do
    name="${f:t:r}"     # basename without extension
    print -r -- "$name"
  done
}

# Load a command file by name
_ezsh_load_cmd() {
  emulate -L zsh
  local cmd="$1"
  local file="${EZSH_COMMANDS_DIR}/${cmd}.zsh"
  [[ -f "$file" ]] || return 1
  source "$file"
  return 0
}

# Main entry
ezsh() {
  emulate -L zsh
  setopt localoptions no_unset

  local cmd="${1:-}"
  if [[ -z "$cmd" ]]; then
    _ezsh_usage
    return 1
  fi

  # Only shift when we actually have at least 1 arg
  shift

  case "$cmd" in
    help|-h|--help)
      _ezsh_usage
      return 0
      ;;
    list)
      _ezsh_list_cmds
      return 0
      ;;
  esac

  # Load custom command definition file
  if ! _ezsh_load_cmd "$cmd"; then
    print -r -- "ezsh: unknown command: $cmd"
    print -r -- ""
    _ezsh_usage
    return 1
  fi

  # Convention: each command file defines ezsh_cmd_<name>() and optional ezsh_desc_<name>
  local fn="ezsh_cmd_${cmd}"
  if (( ${+functions[$fn]} )); then
    "$fn" "$@"
  else
    print -r -- "ezsh: '${cmd}' loaded, but function ${fn} not found."
    print -r -- "Expected your file to define: ${fn}()"
    return 1
  fi
}

# -------------------------
# Completion
# -------------------------
_ezsh() {
  emulate -L zsh
  setopt localoptions null_glob

  local -a cmds
  local f
  cmds=(help list)

  for f in "${EZSH_COMMANDS_DIR}"/*.zsh; do
    cmds+=("${f:t:r}")
  done

  _describe -t commands 'ezsh commands' cmds
}

compdef _ezsh ezsh