# zsh-autocomplete styles
zstyle ':autocomplete:*complete*:*' insert-unambiguous yes
zstyle ':autocomplete:*history*:*' insert-unambiguous yes
zstyle ':autocomplete:menu-search:*' insert-unambiguous yes
zstyle ':autocomplete:recent-paths:*' list-lines 10
zstyle ':autocomplete:history-incremental-search-backward:*' list-lines 10
zstyle ':autocomplete:history-search-backward:*' list-lines 20

# Basic completion matching
zstyle ':completion:*:*' matcher-list 'm:{[:lower:]-}={[:upper:]_}' '+r:|[.]=**'
