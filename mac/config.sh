#!/bin/bash
set -euo pipefail

# ==========================================
# Configuration and Paths
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo ">>> Starting configuration setup..."
echo "    Root Config Dir: $ROOT_DIR"
echo "    Mac Configs Dir: $SCRIPT_DIR"

# ==========================================
# Copy Configurations
# ==========================================

backup_file() {
  if [ -f "$1" ] && [ ! -f "$1.bak" ]; then
    echo "Backing up $1 to $1.bak"
    cp "$1" "$1.bak"
  fi
}

echo ">>> Copying configuration files..."

# Neovim
echo "Configuring Neovim..."
mkdir -p "$HOME/.config/nvim"
backup_file "$HOME/.config/nvim/init.lua"
cp "$ROOT_DIR/common/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"

# Neovide
echo "Configuring Neovide..."
mkdir -p "$HOME/.config/neovide"
backup_file "$HOME/.config/neovide/config.toml"
cp "$ROOT_DIR/common/.config/neovide/config.toml" "$HOME/.config/neovide/config.toml"

# Omnisharp
echo "Configuring Omnisharp..."
mkdir -p "$HOME/.omnisharp"
backup_file "$HOME/.omnisharp/omnisharp.json"
cp "$ROOT_DIR/common/.omnisharp/omnisharp.json" "$HOME/.omnisharp/omnisharp.json"

# Ghostty
echo "Configuring Ghostty..."
mkdir -p "$HOME/.config/ghostty"
backup_file "$HOME/.config/ghostty/config"
cp "$SCRIPT_DIR/.config/ghostty/config" "$HOME/.config/ghostty/config"

# Starship
echo "Configuring Starship..."
mkdir -p "$HOME/.config"
backup_file "$HOME/.config/starship.toml"
cp "$SCRIPT_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

# Git
echo "Configuring Git..."
backup_file "$HOME/.gitconfig"
cp "$ROOT_DIR/common/.gitconfig" "$HOME/.gitconfig"

# .zshrc
echo "Configuring .zshrc..."
backup_file "$HOME/.zshrc"
cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

echo ">>> Configuration Complete!"
echo "    Please restart your terminal or run 'source ~/.zshrc' to apply changes."
