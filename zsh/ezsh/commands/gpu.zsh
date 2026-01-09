# ezsh gpu
# Quick GPU inspection helpers

ezsh_desc_gpu="Inspect GPU status (summary / watch / who / run command)"

ezsh_cmd_gpu() {
  emulate -L zsh
  setopt localoptions no_unset

  local subcmd="${1:-}"

  case "$subcmd" in
    run)
      shift
      _ezsh_gpu_run "$@"
      return
      ;;
    watch|who|"")
      if ! command -v nvidia-smi &>/dev/null; then
        print -r -- "nvidia-smi not found (no NVIDIA GPU?)"
        return 1
      fi
      ;;
    *)
      print -r -- "Usage: ezsh gpu [watch|who|run]"
      return 1
      ;;
  esac

  case "$subcmd" in
    watch)
      print -r -- "Watching GPU status (Ctrl-C to quit)..."
      if command -v watch &>/dev/null; then
        watch -n 1 nvidia-smi
      else
        while true; do
          clear
          date
          nvidia-smi
          sleep 1
        done
      fi
      ;;
    who)
      _ezsh_gpu_who
      ;;
    "")
      _ezsh_gpu_summary
      ;;
  esac
}

_ezsh_gpu_summary() {
  print -r -- "=== GPU Summary ==="
  nvidia-smi --query-gpu=index,name,temperature.gpu,utilization.gpu,memory.used,memory.total \
             --format=csv,noheader,nounits |
  awk -F', ' '
  {
    printf "GPU %s | %-30s | %3sC | util %3s%% | mem %6s / %6s MB\n",
           $1, $2, $3, $4, $5, $6
  }'
  print -r -- "==================="
}

_ezsh_gpu_who() {
  print -r -- "=== GPU Users ==="
  nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory \
             --format=csv,noheader,nounits |
  while IFS=',' read -r uuid pid pname mem; do
    uuid="${uuid// /}"
    pid="${pid// /}"
    mem="${mem// /}"
    local user cmd
    user="$(ps -o user= -p "$pid" 2>/dev/null | tr -d ' ')"
    cmd="$(ps -o command= -p "$pid" 2>/dev/null)"
    printf "PID %-7s | %-8s | %6s MB | %s\n" "$pid" "${user:-?}" "$mem" "$cmd"
  done
  print -r -- "=================="
}

_ezsh_gpu_run() {
  emulate -L zsh

  local opt_gpu=""
  local OPTIND=1
  local opt
  while getopts ":b:" opt; do
    case "$opt" in
      b)
        opt_gpu="$OPTARG"
        ;;
      *)
        _ezsh_gpu_run_usage
        return 2
        ;;
    esac
  done
  shift $((OPTIND-1))

  if (( $# == 0 )); then
    _ezsh_gpu_run_usage
    return 2
  fi

  if [[ -z "$opt_gpu" ]]; then
    print -r -- "ezsh gpu run: -b <devices> is required"
    return 2
  fi

  CUDA_VISIBLE_DEVICES="$opt_gpu" "$@"
}

_ezsh_gpu_run_usage() {
  print -r -- "Usage: ezsh gpu run -b <devices> <command...>"
}
