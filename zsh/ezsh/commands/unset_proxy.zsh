ezsh_desc_unset_proxy="Unset proxy environment variables"
ezsh_cmd_unset_proxy() {
  emulate -L zsh

  unset http_proxy
  unset https_proxy
  unset all_proxy

  print -r -- "Cleared http_proxy, https_proxy, all_proxy"
}
