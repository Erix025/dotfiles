ANTIGEN_ZSH_LOCAL="$ZSH_DOTDIR/antigen.zsh"
ANTIGEN_HOME="$HOME/.antigen"
ANTIGEN_ZSH="$ANTIGEN_ZSH_LOCAL"
[[ -r "$ANTIGEN_ZSH" ]] || ANTIGEN_ZSH="$ANTIGEN_HOME/antigen.zsh"
ANTIGEN_URL="https://raw.githubusercontent.com/zsh-users/antigen/master/antigen.zsh"

if [[ "$ANTIGEN_ZSH" == "$ANTIGEN_HOME/antigen.zsh" && ! -r "$ANTIGEN_ZSH" ]]; then
  mkdir -p "$ANTIGEN_HOME" || return 1
  command curl -fsSL "$ANTIGEN_URL" -o "$ANTIGEN_ZSH" || {
    echo "[zsh] Failed to download antigen from: $ANTIGEN_URL"
    return 1
  }
fi

source "$ANTIGEN_ZSH"
