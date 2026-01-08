ezsh_desc_reload="Reload zsh config"
ezsh_cmd_reload() {
  echo "[ezsh] Reloading zsh..."
  exec zsh -l
}
