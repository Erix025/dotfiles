ZSH_HIGHLIGHT_HIGHLIGHTERS+=(main brackets regexp)
typeset -A ZSH_HIGHLIGHT_REGEXP
ZSH_HIGHLIGHT_REGEXP+=('^(.* )?rm -rf.*' fg=white,bold,bg=red)
