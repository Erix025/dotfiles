export PATH=$HOME/go/bin:/opt/homebrew/opt/node@22/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH

zstyle ':omz:update' mode reminder  # just remind me to update when it's time

[[ -r ~/.antigen/antigen.zsh ]] ||
	(
		mkdir -p ~/.antigen &&
		curl -L https://shell.haoxx.me/antigen.zsh > ~/.antigen/antigen.zsh
	)

# Helper function for logging and command execution
log_cmd() {
  local cmd="$1"
  local msg="${2:-Executing command}"
  local c_status=0

  # Define colors
  local bold='\033[1m'
  local reset='\033[0m'
  local red='\033[31m'
  local green='\033[32m'
  local yellow='\033[33m'
  local blue='\033[34m'
  local magenta='\033[35m'
  local cyan='\033[36m'

  # Print colored command
  echo -e "${bold}${blue}[${magenta}${msg}${blue}]${reset} ${cyan}${cmd}${reset}"

  # Execute command
  eval "$cmd"
  c_status=$?

  # Show status if not successful
  if [[ $c_status -ne 0 ]]; then
    echo -e "${bold}${red}[Error]${reset} Command failed with status ${c_status}"
  fi

  return $c_status
}

starsh() {
  local proxyurl="https://shell.haoxx.me/proxy/"
  if [[ "$1" == "update" ]]; then
    echo "Updating .zshrc from https://shell.haoxx.me/zshrc"
    if [[ "$(uname -n | cut -d. -f1)" == "starmbp" ]]; then
      echo "not updating .zshrc on starmbp"
      return
    fi

    local backup_file=~/.zshrc.old

    log_cmd "cp ~/.zshrc \"$backup_file\"" "Backup"
    echo "Current .zshrc backed up to $backup_file"

    if log_cmd "curl -L https://shell.haoxx.me/zshrc -o ~/.zshrc" "Download"; then
      log_cmd "exec zsh" "Reloading"
    else
      echo "Failed to download .zshrc, Restoring backup"
      log_cmd "cp \"$backup_file\" ~/.zshrc" "Restore"
    fi
  elif [[ "$1" == "install-eza" ]]; then
    echo "Installing eza (overwrite if exists)"
    if [[ ! -d "$HOME/.local/bin" ]]; then
      echo "Creating ~/.local/bin directory"
      log_cmd "mkdir -p \"$HOME/.local/bin\"" "Setup"
    fi

    echo "Installing eza to ~/.local/bin"

    local os_type=$(uname)
    local arch_type=$(uname -m)
    local download_url=""

    if [[ "$os_type" == "Linux" && "$arch_type" == "aarch64" ]]; then
      download_url=$proxyurl"https://github.com/eza-community/eza/releases/latest/download/eza_aarch64-unknown-linux-gnu_no_libgit.tar.gz"
    elif [[ "$os_type" == "Linux" && "$arch_type" == "x86_64" ]]; then
      download_url=$proxyurl"https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-musl.tar.gz"
    else
      echo "Unsupported OS/architecture: $os_type/$arch_type"
      return 1
    fi

    local temp_dir=$(mktemp -d)

    if log_cmd "curl -L \"$download_url\" -o \"$temp_dir/eza.tar.gz\"" "Download"; then
      echo "Download successful, extracting..."

      log_cmd "tar -xzf \"$temp_dir/eza.tar.gz\" -C \"$temp_dir\"" "Extract"

      if [[ -f "$temp_dir/eza" ]]; then
        log_cmd "mv -v \"$temp_dir/eza\" \"$HOME/.local/bin/\"" "Install"
        log_cmd "chmod +x \"$HOME/.local/bin/eza\"" "Permissions"
        echo "eza has been installed to ~/.local/bin/eza"
      else
        echo "Failed to extract eza binary"
        return 1
      fi
    else
      echo "Failed to download eza"
      return 1
    fi

    log_cmd "rm -rf \"$temp_dir\"" "Cleanup"
    if command -v eza &>/dev/null; then
      echo "Installation successful!"
      eza --version
    else
      echo "Installation may have succeeded, but eza is not in your PATH"
      echo "Make sure ~/.local/bin is in your PATH and restart your shell"
    fi
  elif [[ "$1" == "install-golang" ]]; then
    echo "Installing Go (overwrite if exists)"
    if [[ ! -d "$HOME/.local/bin" ]]; then
      echo "Creating ~/.local/bin directory"
      log_cmd "mkdir -p \"$HOME/.local/bin\"" "Setup"
    fi

    local os_type=$(uname)
    local arch_type=$(uname -m)
    local go_version="1.24.2"  # Default Go version - change as needed
    local download_url=""

    # Allow specifying Go version as the second argument
    if [[ -n "$2" ]]; then
      go_version="$2"
    fi

    echo "Installing Go version ${go_version}"

    # Map OS and architecture to Go download URL format
    if [[ "$os_type" == "Linux" && "$arch_type" == "x86_64" ]]; then
      download_url="${proxyurl}https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"
    elif [[ "$os_type" == "Linux" && "$arch_type" == "aarch64" ]]; then
      download_url="${proxyurl}https://go.dev/dl/go${go_version}.linux-arm64.tar.gz"
    elif [[ "$os_type" == "Darwin" && "$arch_type" == "x86_64" ]]; then
      download_url="${proxyurl}https://go.dev/dl/go${go_version}.darwin-amd64.tar.gz"
    elif [[ "$os_type" == "Darwin" && "$arch_type" == "arm64" ]]; then
      download_url="${proxyurl}https://go.dev/dl/go${go_version}.darwin-arm64.tar.gz"
    else
      echo "Unsupported OS/architecture: $os_type/$arch_type"
      return 1
    fi

    local temp_dir=$(mktemp -d)
    echo "Downloading Go from $download_url"

    if log_cmd "curl -L \"$download_url\" -o \"$temp_dir/go.tar.gz\"" "Download"; then
      echo "Download successful, extracting..."

      if [[ -d "$HOME/.local/go" ]]; then
        echo "Removing existing Go installation"
        log_cmd "rm -rf \"$HOME/.local/go\"" "Remove old"
      fi

      log_cmd "tar -C \"$HOME/.local\" -xzf \"$temp_dir/go.tar.gz\"" "Extract"

      if [[ -d "$HOME/.local/go/bin" ]]; then
        # Create symlinks to common Go binaries in ~/.local/bin
        echo "Creating symlinks for Go binaries in ~/.local/bin"
        log_cmd "ln -sf \"$HOME/.local/go/bin/go\" \"$HOME/.local/bin/go\"" "Symlink go"
        log_cmd "ln -sf \"$HOME/.local/go/bin/gofmt\" \"$HOME/.local/bin/gofmt\"" "Symlink gofmt"

        echo "Go has been installed to ~/.local/go"
        echo "Go binaries are symlinked in ~/.local/bin"
      else
        echo "Failed to extract Go"
        return 1
      fi
    else
      echo "Failed to download Go"
      return 1
    fi

    log_cmd "rm -rf \"$temp_dir\"" "Cleanup"

    # Check if Go is in PATH
    if command -v go &>/dev/null; then
      echo "Installation successful!"
      go version
    else
      echo "Installation may have succeeded, but go is not in your PATH"
      echo "Make sure ~/.local/bin is in your PATH and restart your shell"
    fi
  elif [[ "$1" == "install-nvim" ]]; then
    echo "Installing Neovim AppImage"
    if [[ ! -d "$HOME/.local/bin" ]]; then
      echo "Creating ~/.local/bin directory"
      log_cmd "mkdir -p \"$HOME/.local/bin\"" "Setup"
    fi

    local os_type=$(uname)
    local arch_type=$(uname -m)
    local nvim_version="0.11.0"  # Default Neovim version
    local download_url=""
    local use_old_glibc=false

    # Parse arguments
    for arg in "$@"; do
      if [[ "$arg" == "--old-glibc" ]]; then
        use_old_glibc=true
      elif [[ "$arg" != "install-nvim" ]]; then
        nvim_version="$arg"
      fi
    done

    echo "Installing Neovim version ${nvim_version}"

    # Only proceed if on Linux
    if [[ "$os_type" != "Linux" ]]; then
      echo "This command only supports Linux. For macOS, use a package manager like brew."
      return 1
    fi

    # Map architecture to Neovim AppImage URL format
    if [[ "$arch_type" == "x86_64" ]]; then
      if [[ "$use_old_glibc" == true ]]; then
        download_url="${proxyurl}https://github.com/neovim/neovim-releases/releases/download/v${nvim_version}/nvim-linux-x86_64.appimage"
        echo "Using old-glibc compatible version"
      else
        download_url="${proxyurl}https://github.com/neovim/neovim/releases/download/v${nvim_version}/nvim-linux-x86_64.appimage"
      fi
    elif [[ "$arch_type" == "aarch64" || "$arch_type" == "arm64" ]]; then
      if [[ "$use_old_glibc" == true ]]; then
        echo "Not supported for old-glibc"
        return 1
      else
        download_url="${proxyurl}https://github.com/neovim/neovim/releases/download/v${nvim_version}/nvim-linux-arm64.appimage"
      fi
    else
      echo "Unsupported architecture: $arch_type"
      return 1
    fi

    echo "Downloading Neovim AppImage from $download_url"
    local nvim_path="$HOME/.local/bin/nvim"

    if log_cmd "curl -L \"$download_url\" -o \"$nvim_path\"" "Download"; then
      echo "Download successful"
      log_cmd "chmod +x \"$nvim_path\"" "Permissions"

      if command -v nvim &>/dev/null; then
        echo "Installation successful!"
        nvim --version
      else
        echo "Installation completed, but nvim is not in your PATH"
        echo "Make sure ~/.local/bin is in your PATH and restart your shell"
      fi
    else
      echo "Failed to download Neovim AppImage"
      return 1
    fi
  elif [[ "$1" == "install-lazyvim" ]]; then
    echo "Installing LazyVim Neovim configuration"

    # Backup existing Neovim configuration
    if [[ -d "$HOME/.config/nvim" ]]; then
      echo "Backing up existing Neovim configuration"
      log_cmd "mv ~/.config/nvim{,.bak}" "Backup config"
    fi

    # Optional backups (recommended)
    if [[ -d "$HOME/.local/share/nvim" ]]; then
      log_cmd "mv ~/.local/share/nvim{,.bak}" "Backup share"
    fi

    if [[ -d "$HOME/.local/state/nvim" ]]; then
      log_cmd "mv ~/.local/state/nvim{,.bak}" "Backup state"
    fi

    if [[ -d "$HOME/.cache/nvim" ]]; then
      log_cmd "mv ~/.cache/nvim{,.bak}" "Backup cache"
    fi

    log_cmd "git clone ${proxyurl}https://github.com/LazyVim/starter ~/.config/nvim" "Clone starter"

    log_cmd "rm -rf ~/.config/nvim/.git" "Clean git"

    echo "LazyVim has been installed successfully!"
    echo "Running Neovim to complete setup and install plugins..."
    echo "Note: First run may show some errors while plugins are being installed."
    echo "Press any key to launch Neovim or Ctrl+C to exit"
    read -k
    nvim
  else
    echo "Unknown starsh command: $1"
    echo "Available commands: update, install-eza, install-golang, install-nvim, install-lazyvim"
  fi
}

# Define completion for starsh function
_starsh() {
  local context state line
  typeset -A opt_args

  _arguments -C \
    '1:command:->command' \
    '*::options:->options'

  case $state in
    (command)
      local -a commands
      commands=(
        'update:Update .zshrc from shell.haoxx.me'
        'install-eza:Install eza from GitHub'
        'install-golang:Install Go from go.dev'
        'install-nvim:Install Neovim AppImage'
        'install-lazyvim:Install LazyVim Neovim configuration'
      )
      _describe -t commands 'starsh commands' commands
      ;;
    (options)
      case $line[1] in
        (install-golang)
          _arguments \
            '1:Go version (e.g., 1.24.2):'
          ;;
        (install-nvim)
          _arguments \
            '1:Neovim version (e.g., 0.11.0):' \
            '--old-glibc[Use old-glibc compatible AppImage]'
          ;;
      esac
      ;;
  esac
}

source ~/.antigen/antigen.zsh

HIST_STAMPS="yyyy-mm-dd"

ZSH_HIGHLIGHT_HIGHLIGHTERS+=(main brackets regexp)
typeset -A ZSH_HIGHLIGHT_REGEXP
ZSH_HIGHLIGHT_REGEXP+=('^(.* )?rm -rf.*' fg=white,bold,bg=red)


antigen use oh-my-zsh
antigen bundle git
antigen bundle sudo
antigen bundle command-not-found
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle marlonrichert/zsh-autocomplete@24.09.04
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle mrhaoxx/zsh-cmd-status@main
antigen bundle colorize
antigen bundle eza
antigen bundle vscode
antigen bundle z

# if [[ "$(uname -n | cut -d. -f1)" == "starmbp" ]]; then
#   antigen theme robbyrussell
# else
#   antigen theme fishy
# fi

antigen apply

# Register the completion function
compdef _starsh starsh

bindkey              '^I' menu-select
bindkey "$terminfo[kcbt]" menu-select

bindkey -M menuselect              '^I'         menu-complete
bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete
bindkey -M menuselect '\r' .accept-line


# all Tab widgets
zstyle ':autocomplete:*complete*:*' insert-unambiguous yes
# all history widgets
zstyle ':autocomplete:*history*:*' insert-unambiguous yes
# ^S
zstyle ':autocomplete:menu-search:*' insert-unambiguous yes

#
zstyle ':autocomplete:recent-paths:*' list-lines 10
zstyle ':autocomplete:history-incremental-search-backward:*' list-lines 10
zstyle ':autocomplete:history-search-backward:*' list-lines 20

zstyle ':completion:*:*' matcher-list 'm:{[:lower:]-}={[:upper:]_}' '+r:|[.]=**'
zstyle ':completion:*' completer _complete _complete:-fuzzy _correct _approximate _ignored


bindkey -M menuselect  '^[[D' .backward-char  '^[OD' .backward-char
bindkey -M menuselect  '^[[C'  .forward-char  '^[OC'  .forward-char

# export ARCHFLAGS="-arch x86_64"
# export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

if command -v conda &>/dev/null; then
  eval "$(conda 'shell.'$(basename "$SHELL") hook)"
fi
if command -v micromamba &>/dev/null; then
  eval "$(micromamba shell hook -s zsh)"
fi

alias vi=nvim
alias git='LANG=en_US git'

source ~/dotfiles/zsh/headline.zsh-theme
# source $ZSH/oh-my-zsh.sh