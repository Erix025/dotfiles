bindkey '^I' menu-select
bindkey "$terminfo[kcbt]" menu-select

bindkey -M menuselect '^I' menu-complete
bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete
bindkey -M menuselect '\r' .accept-line

bindkey -M menuselect '^[[D' .backward-char  '^[OD' .backward-char
bindkey -M menuselect '^[[C' .forward-char   '^[OC'  .forward-char

autoload -Uz add-zsh-hook
_headline_bind_ctrl_l() {
  if (( $+functions[headline-clear-screen] )); then
    zle -N headline-clear-screen
    bindkey '^L' headline-clear-screen
    add-zsh-hook -d precmd _headline_bind_ctrl_l
  fi
}
add-zsh-hook -Uz precmd _headline_bind_ctrl_l
