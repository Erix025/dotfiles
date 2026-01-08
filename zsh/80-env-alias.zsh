# Optional: enable by env var to avoid slow startup / conflicts
#   export ZSH_ENABLE_CONDA=1
#   export ZSH_ENABLE_MICROMAMBA=1
if [[ "${ZSH_ENABLE_CONDA:-0}" == "1" ]] && command -v conda &>/dev/null; then
  eval "$(conda "shell.$(basename "$SHELL")" hook)"
fi

if [[ "${ZSH_ENABLE_MICROMAMBA:-0}" == "1" ]] && command -v micromamba &>/dev/null; then
  eval "$(micromamba shell hook -s zsh)"
fi

alias vi='nvim'
git() { LANG=en_US command git "$@"; }

export HOMEBREW_NO_AUTO_UPDATE=1

if [[ -f "$HOME/.config/claude_api_key" ]]; then
  export ANTHROPIC_AUTH_TOKEN="$(<"$HOME/.config/claude_api_key")"
fi
