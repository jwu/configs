#!/bin/bash
set -euo pipefail

# ==========================================
# Configuration and Paths
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo ">>> Starting installation setup..."
echo "    Root Config Dir: $ROOT_DIR"
echo "    Mac Configs Dir: $SCRIPT_DIR"

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
  "coreutils"
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
  "neovide"
  "font-fira-mono-nerd-font"
)

echo "Installing packages: ${PACKAGES[*]}"
brew install "${PACKAGES[@]}"

echo "Installing casks: ${CASKS[*]}"
brew install --cask "${CASKS[@]}"

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
