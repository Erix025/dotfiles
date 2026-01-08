ezsh_desc_gpurun="Run command with CUDA_VISIBLE_DEVICES"
ezsh_cmd_gpurun() {
  local opt_gpu=""
  local OPTIND=1
  local opt
  while getopts ":b:" opt; do
    case "$opt" in
      b)
        opt_gpu="$OPTARG"
        ;;
      *)
        echo "Usage: gpurun -b <devices> <command...>" >&2
        return 2
        ;;
    esac
  done
  shift $((OPTIND-1))

  if (( $# == 0 )); then
    echo "Usage: gpurun -b <devices> <command...>" >&2
    return 2
  fi

  if [[ -z "$opt_gpu" ]]; then
    echo "gpurun: -b <devices> is required" >&2
    return 2
  fi

  CUDA_VISIBLE_DEVICES="$opt_gpu" "$@"
}
