#!/bin/bash
set -euo pipefail

# ==========================================
# Configuration and Paths
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo ">>> Starting configuration setup..."
echo "    Root Config Dir: $ROOT_DIR"
echo "    Linux Configs Dir: $SCRIPT_DIR"

# ==========================================
# Copy Configurations
# ==========================================

backup_file() {
  if [ -f "$1" ]; then
    echo "Backing up $1 to $1.bak"
    cp "$1" "$1.bak"
  fi
}

echo ">>> Copying configuration files..."

# TTY Font
echo ">>> Configuring tty font..."
CONFIG_FILE="/etc/vconsole.conf"
FONT_NAME="ter-v16n"
if [ -f "$CONFIG_FILE" ] && grep -q "^FONT=" "$CONFIG_FILE"; then
  sudo sed -i "s/^FONT=.*/FONT=$FONT_NAME/" "$CONFIG_FILE"
else
  echo "FONT=$FONT_NAME" | sudo tee -a "$CONFIG_FILE" > /dev/null
fi

# Fcitx5 / input method environment
mkdir -p "$HOME/.config/environment.d"
backup_file "$HOME/.config/environment.d/fcitx5.conf"
cp "$SCRIPT_DIR/.config/environment.d/fcitx5.conf" "$HOME/.config/environment.d/fcitx5.conf"

# Niri
if command -v niri &> /dev/null; then
  echo "Configuring Niri..."
  mkdir -p "$HOME/.config/niri"
  backup_file "$HOME/.config/niri/config.kdl"
  cp "$SCRIPT_DIR/.config/niri/config.kdl" "$HOME/.config/niri/config.kdl"
fi

# Swaylock
if command -v swaylock &> /dev/null; then
  echo "Configuring Swaylock..."
  SWAYLOCK_BACKGROUND_DIR="$HOME/.config/swaylock/backgrounds"
  mkdir -p "$SWAYLOCK_BACKGROUND_DIR"
  cp -a "$SCRIPT_DIR/backgrounds/." "$SWAYLOCK_BACKGROUND_DIR/"
  mkdir -p "$HOME/.config/swaylock"
  backup_file "$HOME/.config/swaylock/config"
  sed "s|__SWAYLOCK_BACKGROUND_DIR__|$SWAYLOCK_BACKGROUND_DIR|g" \\
    "$SCRIPT_DIR/.config/swaylock/config" > "$HOME/.config/swaylock/config"
fi

# Hyprland
if command -v hyprland &> /dev/null; then
  echo "Configuring Hyprland..."
  mkdir -p "$HOME/.config/hypr"
  backup_file "$HOME/.config/hypr/hyprland.lua"
  cp "$SCRIPT_DIR/.config/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"
fi

# Clipboard history helper
if command -v cliphist &> /dev/null && command -v fuzzel &> /dev/null && command -v wl-copy &> /dev/null && command -v wl-paste &> /dev/null && command -v wtype &> /dev/null; then
  echo "Configuring clipboard history helper..."
  mkdir -p "$HOME/.local/bin"
  cp "$SCRIPT_DIR/.local/bin/niri-clipboard-history" "$HOME/.local/bin/niri-clipboard-history"
  chmod +x "$HOME/.local/bin/niri-clipboard-history"
fi

# Ghostty
if command -v ghostty &> /dev/null; then
  echo "Configuring Ghostty..."
  mkdir -p "$HOME/.config/ghostty"
  backup_file "$HOME/.config/ghostty/config.ghostty"
  cp "$SCRIPT_DIR/.config/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
fi

# EZA
echo "Configuring EZA..."
mkdir -p "$HOME/.config/eza"

# Neovim
echo "Configuring Neovim..."
mkdir -p "$HOME/.config/nvim"
backup_file "$HOME/.config/nvim/init.lua"
cp "$ROOT_DIR/common/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"

# Omnisharp
echo "Configuring Omnisharp..."
mkdir -p "$HOME/.omnisharp"
backup_file "$HOME/.omnisharp/omnisharp.json"
cp "$ROOT_DIR/common/.omnisharp/omnisharp.json" "$HOME/.omnisharp/omnisharp.json"

# Starship
echo "Configuring Starship..."
mkdir -p "$HOME/.config"
backup_file "$HOME/.config/starship.toml"
if [ -f "$SCRIPT_DIR/.config/starship.toml" ]; then
  cp "$SCRIPT_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
fi

# Alacritty (optional for TTY systems, skip if not needed)
if command -v alacritty &> /dev/null; then
  echo "Configuring Alacritty..."
  mkdir -p "$HOME/.config/alacritty"
  backup_file "$HOME/.config/alacritty/alacritty.toml"
  if [ -f "$SCRIPT_DIR/.config/alacritty/alacritty.toml" ]; then
    cp "$SCRIPT_DIR/.config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
  fi
fi

# .zshrc
echo "Configuring .zshrc..."
backup_file "$HOME/.zshrc"
if [ -f "$SCRIPT_DIR/.zshrc" ]; then
  cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
fi

echo ">>> Configuration Complete!"
echo "    Please restart your terminal or run 'source ~/.zshrc' to apply changes."
