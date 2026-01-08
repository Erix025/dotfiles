path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/go/bin"
  "/opt/homebrew/opt/node@22/bin"
  "/opt/homebrew/bin"
  "/usr/local/bin"
  $path
)
export PATH

# If you use pixi often, uncomment:
path=("$HOME/.pixi/bin" $path)
