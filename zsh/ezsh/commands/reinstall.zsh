ezsh_desc_reinstall="Git pull dotfiles then reload zsh"
ezsh_cmd_reinstall() {
  emulate -L zsh

  local repo="${HOME}/dotfiles"

  if [[ ! -d "$repo/.git" ]]; then
    print -r -- "reinstall: ${repo} is not a git repository"
    return 1
  fi

  print -r -- "[reinstall] Running git pull in ${repo}"
  if ! git -C "$repo" pull --ff-only; then
    print -r -- "reinstall: git pull failed"
    return 1
  fi

  print -r -- "[reinstall] Reloading shell"
  ezsh reload
}
