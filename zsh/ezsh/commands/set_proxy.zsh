ezsh_desc_set_proxy="Set proxy environment variables"
ezsh_cmd_set_proxy() {
  emulate -L zsh

  if (( $# != 1 )); then
    print -r -- "Usage: set_proxy <port|surge>"
    return 2
  fi

  local arg="$1"
  local http_val=""
  local https_val=""
  local all_val=""

  case "$arg" in
    surge)
      http_val="http://127.0.0.1:6152"
      https_val="http://127.0.0.1:6152"
      all_val="socks5://127.0.0.1:6153"
      ;;
    <->)
      http_val="http://localhost:${arg}"
      https_val="$http_val"
      all_val="$http_val"
      ;;
    *)
      print -r -- "set_proxy: invalid argument '$arg'"
      print -r -- "Usage: set_proxy <port|surge>"
      return 2
      ;;
  esac

  export http_proxy="$http_val"
  export https_proxy="$https_val"
  export all_proxy="$all_val"

  print -r -- "http_proxy=$http_proxy"
  print -r -- "https_proxy=$https_proxy"
  print -r -- "all_proxy=$all_proxy"
}
