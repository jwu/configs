#!/bin/bash
set -e

# ==========================================
# Configuration and Paths
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo ">>> Starting installation setup..."
echo "    Root Config Dir: $ROOT_DIR"
echo "    Mac Settings Dir: $SCRIPT_DIR"

# ==========================================
# Homebrew Packages
# ==========================================

if ! command -v brew &> /dev/null; then
  echo "Error: Homebrew is not installed. Please install it first."
  exit 1
fi

echo ">>> Installing/Updating packages via Homebrew..."
brew update

PACKAGES=(
  "starship"
  "zoxide"
  "neovim"
  "fzf"
  "eza"
  "fd"
  "bat"
  "delta"
)

CASKS=(
  "wezterm@nightly"
  "alacritty"
  "neovide"
  "font-fira-mono-nerd-font"
)

echo "Installing packages: ${PACKAGES[*]}"
brew install "${PACKAGES[@]}"

echo "Installing casks: ${CASKS[*]}"
# ensure font cask is available (fonts are now in main cask repo, but just in case for older brew setups)
brew tap homebrew/cask-fonts 2>/dev/null || true
brew install --cask "${CASKS[@]}" || echo "Some casks might already be installed."

# ==========================================
# Oh My Zsh Setup
# ==========================================

echo ">>> Setting up Oh My Zsh..."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh is already installed."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ==========================================
# Plugins: zsh-autosuggestions
# ==========================================

echo ">>> Installing zsh-autosuggestions..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
  echo "zsh-autosuggestions already exists, pulling latest..."
  cd "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && git pull && cd - > /dev/null
fi

# ==========================================
# Theme: Dracula
# ==========================================

echo ">>> Installing Dracula Zsh Theme..."
OH_MY_ZSH="$HOME/.oh-my-zsh"
TEMP_DIR=$(mktemp -d)

if [ ! -f "$OH_MY_ZSH/themes/dracula.zsh-theme" ]; then
  curl -fsSL "https://github.com/dracula/zsh/archive/master.zip" -o "$TEMP_DIR/dracula.zip"
  unzip -q "$TEMP_DIR/dracula.zip" -d "$TEMP_DIR"
  cp "$TEMP_DIR/zsh-master/dracula.zsh-theme" "$OH_MY_ZSH/themes/dracula.zsh-theme"
  cp -r "$TEMP_DIR/zsh-master/lib" "$OH_MY_ZSH/themes/lib"
  rm -rf "$TEMP_DIR"
  echo "  Dracula Zsh Theme installed"
else
  echo "  Dracula Zsh Theme already installed"
fi

# ==========================================
# Copy Configurations
# ==========================================

bash "$SCRIPT_DIR/config.sh"
