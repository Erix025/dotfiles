antigen use oh-my-zsh

# Core
antigen bundle git
antigen bundle sudo
antigen bundle command-not-found

# Completion / Suggestion
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle marlonrichert/zsh-autocomplete@24.09.04
antigen bundle zsh-users/zsh-history-substring-search

# QoL
antigen bundle mrhaoxx/zsh-cmd-status@main
antigen bundle colorize
antigen bundle z
antigen bundle vscode
antigen bundle eza  # 可选：只为 alias/补全；不需要可以删

# Highlighting: typically load late
antigen bundle zsh-users/zsh-syntax-highlighting

antigen apply
