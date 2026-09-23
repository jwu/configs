#!/bin/bash
set -euo pipefail

# ==========================================
# Configuration and Paths
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo ">>> Starting configuration setup..."
echo "    Root Config Dir: $ROOT_DIR"
echo "    Mac Configs Dir: $SCRIPT_DIR"

# ==========================================
# Copy Configurations
# ==========================================

backup_file() {
  if [ -f "$1" ]; then
    echo "Backing up $1 to $1.bak.$TIMESTAMP"
    cp "$1" "$1.bak.$TIMESTAMP"
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

# Git (XDG path; leaves ~/.gitconfig and an existing identity alone)
echo "Configuring Git..."
mkdir -p "$HOME/.config/git"
backup_file "$HOME/.config/git/config"
cp "$ROOT_DIR/common/.gitconfig" "$HOME/.config/git/config"

# Optional CLI tools: install configs only when the tool is present
if command -v zellij &> /dev/null; then
  echo "Configuring Zellij..."
  mkdir -p "$HOME/.config/zellij"
  backup_file "$HOME/.config/zellij/config.kdl"
  cp "$SCRIPT_DIR/.config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
fi

if command -v yazi &> /dev/null; then
  echo "Configuring Yazi..."
  mkdir -p "$HOME/.config/yazi"
  for f in yazi.toml theme.toml; do
    backup_file "$HOME/.config/yazi/$f"
    cp "$ROOT_DIR/common/.config/yazi/$f" "$HOME/.config/yazi/$f"
  done
fi

if command -v lsd &> /dev/null; then
  echo "Configuring LSD..."
  mkdir -p "$HOME/.config/lsd"
  backup_file "$HOME/.config/lsd/config.yaml"
  cp "$ROOT_DIR/common/.config/lsd/config.yaml" "$HOME/.config/lsd/config.yaml"
fi

if command -v gitui &> /dev/null; then
  echo "Configuring GitUI..."
  mkdir -p "$HOME/.config/gitui"
  backup_file "$HOME/.config/gitui/theme.ron"
  cp "$ROOT_DIR/common/.config/gitui/theme.ron" "$HOME/.config/gitui/theme.ron"
fi

if command -v glow &> /dev/null; then
  echo "Configuring Glow..."
  mkdir -p "$HOME/.config/glow"
  backup_file "$HOME/.config/glow/one-dark.json"
  cp "$ROOT_DIR/common/.config/glow/one-dark.json" "$HOME/.config/glow/one-dark.json"
fi

# .zshrc
echo "Configuring .zshrc..."
backup_file "$HOME/.zshrc"
cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

echo ">>> Configuration Complete!"
echo "    Please restart your terminal or run 'source ~/.zshrc' to apply changes."
