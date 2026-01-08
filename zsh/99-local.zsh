# Put machine-specific/private stuff here
# Example:
#   export STARSH_USE_PROXY=1
#   export STARSH_PROXY_PREFIX="..."
#   path=(/some/special/bin $path)

if [[ -f "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
