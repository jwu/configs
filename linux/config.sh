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
echo "    Linux Configs Dir: $SCRIPT_DIR"

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
  mkdir -p "$HOME/.local/bin"
  cp "$SCRIPT_DIR/.local/bin/niri-open-terminal-below" "$HOME/.local/bin/niri-open-terminal-below"
  chmod +x "$HOME/.local/bin/niri-open-terminal-below"
  cp "$SCRIPT_DIR/.local/bin/niri-lock" "$HOME/.local/bin/niri-lock"
  chmod +x "$HOME/.local/bin/niri-lock"
fi

# Hyprlock (screen locker; see docs/lockscreen.md)
if command -v hyprlock &> /dev/null; then
  echo "Configuring hyprlock..."
  mkdir -p "$HOME/.config/hypr"
  backup_file "$HOME/.config/hypr/hyprlock.conf"
  cp "$SCRIPT_DIR/.config/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
fi

# Waybar
if command -v waybar &> /dev/null; then
  echo "Configuring Waybar..."
  mkdir -p "$HOME/.config/waybar/scripts"
  for f in config.jsonc style.css colors.css; do
    backup_file "$HOME/.config/waybar/$f"
    cp "$SCRIPT_DIR/.config/waybar/$f" "$HOME/.config/waybar/$f"
  done
  # waybar dlopen()s module_path and does not expand ~/$HOME, so substitute an
  # absolute path (same as swaylock below). See docs/waybar.md.
  WAYBAR_MODULE_DIR="$HOME/.config/waybar"
  backup_file "$HOME/.config/waybar/modules.json"
  sed "s|__WAYBAR_MODULE_DIR__|$WAYBAR_MODULE_DIR|g" \
    "$SCRIPT_DIR/.config/waybar/modules.json" > "$HOME/.config/waybar/modules.json"
  # Metric script: the hotter of the two NVMe drives. The GPU metrics come from
  # gpu-watch instead, which install.sh compiles into ~/.local/bin -- it has to
  # be a long-lived process, not something waybar re-runs every 2s. See
  # docs/waybar.md.
  for f in nvme-temp.sh; do
    backup_file "$HOME/.config/waybar/scripts/$f"
    cp "$SCRIPT_DIR/.config/waybar/scripts/$f" "$HOME/.config/waybar/scripts/$f"
    chmod +x "$HOME/.config/waybar/scripts/$f"
  done
  if [ ! -f "$HOME/.config/waybar/waybar-niri-windows.so" ]; then
    echo "    Note: waybar-niri-windows.so missing; run install.sh to install the cffi/niri-windows module."
  fi
  if [ ! -x "$HOME/.local/bin/gpu-watch" ]; then
    echo "    Note: gpu-watch missing; run install.sh to build it (the GPU modules show 'off' without it)."
  fi
fi

# Fcitx5 tray icons. The tray items are drawn by waybar, but the icon names come
# from fcitx5 (Rime's Chinese/Latin states, and the keyboard layout), so they are
# overridden by name under XDG_DATA_HOME. The keyboard-layout one has to mirror
# the Adwaita theme path to win the lookup; see docs/ime-icons.md.
if command -v fcitx5 &> /dev/null; then
  echo "Configuring Fcitx5 tray icons..."
  RIME_ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
  mkdir -p "$RIME_ICON_DIR"
  for f in fcitx-rime.svg fcitx_rime_latin.svg fcitx_rime_latin_upper.svg; do
    backup_file "$RIME_ICON_DIR/$f"
    cp "$SCRIPT_DIR/.local/share/icons/hicolor/scalable/apps/$f" "$RIME_ICON_DIR/$f"
  done
  KEYBOARD_ICON_DIR="$HOME/.local/share/icons/Adwaita/symbolic/devices"
  mkdir -p "$KEYBOARD_ICON_DIR"
  backup_file "$KEYBOARD_ICON_DIR/input-keyboard-symbolic.svg"
  cp "$SCRIPT_DIR/.local/share/icons/Adwaita/symbolic/devices/input-keyboard-symbolic.svg" \
    "$KEYBOARD_ICON_DIR/input-keyboard-symbolic.svg"
fi

# Wallpapers: shared by swaylock and hyprlock, which references one of these
# files directly (see docs/lockscreen.md), so copy them whichever locker ends up
# installed.
SWAYLOCK_BACKGROUND_DIR="$HOME/.config/swaylock/backgrounds"
mkdir -p "$SWAYLOCK_BACKGROUND_DIR"
cp -a "$SCRIPT_DIR/backgrounds/." "$SWAYLOCK_BACKGROUND_DIR/"

# Swaylock (the fallback locker; hyprlock is the primary one)
if command -v swaylock &> /dev/null; then
  echo "Configuring Swaylock..."
  backup_file "$HOME/.config/swaylock/config"
  sed "s|__SWAYLOCK_BACKGROUND_DIR__|$SWAYLOCK_BACKGROUND_DIR|g" \
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
else
  echo "    Note: clipboard helper not installed (missing cliphist/fuzzel/wl-clipboard/wtype); Mod+Shift+V will not work."
fi

# Ghostty
if command -v ghostty &> /dev/null; then
  echo "Configuring Ghostty..."
  mkdir -p "$HOME/.config/ghostty"
  backup_file "$HOME/.config/ghostty/config.ghostty"
  cp "$SCRIPT_DIR/.config/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
  # GTK titlebar tweaks: slim headerbar + color presets
  # (config.ghostty loads them via `gtk-custom-css = ~/.config/ghostty/...`)
  for f in titlebar.css titlebar-colors-onedark.css titlebar-colors-onedark-purple.css titlebar-colors-default.css; do
    backup_file "$HOME/.config/ghostty/$f"
    cp "$SCRIPT_DIR/.config/ghostty/$f" "$HOME/.config/ghostty/$f"
  done
fi

# GTK4 global tweaks (square CSD window corners; applies to all GTK4 apps)
if [ -f "$SCRIPT_DIR/.config/gtk-4.0/gtk.css" ]; then
  echo "Configuring GTK4..."
  mkdir -p "$HOME/.config/gtk-4.0"
  backup_file "$HOME/.config/gtk-4.0/gtk.css"
  cp "$SCRIPT_DIR/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
fi

# Neovim
echo "Configuring Neovim..."
mkdir -p "$HOME/.config/nvim"
backup_file "$HOME/.config/nvim/init.lua"
cp "$ROOT_DIR/common/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"

# Neovide
if command -v neovide &> /dev/null; then
  echo "Configuring Neovide..."
  mkdir -p "$HOME/.config/neovide"
  backup_file "$HOME/.config/neovide/config.toml"
  cp "$ROOT_DIR/common/.config/neovide/config.toml" "$HOME/.config/neovide/config.toml"
  mkdir -p "$HOME/.local/share/applications"
  backup_file "$HOME/.local/share/applications/neovide.desktop"
  cp "$SCRIPT_DIR/neovide.desktop" "$HOME/.local/share/applications/neovide.desktop"
fi

# Omnisharp
echo "Configuring Omnisharp..."
mkdir -p "$HOME/.omnisharp"
backup_file "$HOME/.omnisharp/omnisharp.json"
cp "$ROOT_DIR/common/.omnisharp/omnisharp.json" "$HOME/.omnisharp/omnisharp.json"

# Git (XDG path; leaves ~/.gitconfig and an existing identity alone)
echo "Configuring Git..."
mkdir -p "$HOME/.config/git"
backup_file "$HOME/.config/git/config"
cp "$ROOT_DIR/common/.gitconfig" "$HOME/.config/git/config"

# Starship
echo "Configuring Starship..."
mkdir -p "$HOME/.config"
backup_file "$HOME/.config/starship.toml"
cp "$SCRIPT_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

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

if command -v fcitx5 &> /dev/null; then
  echo "    Note: run desktop-settings/fcitx5/install-linux.sh to install the Fcitx5/Rime profile and theme."
  echo "    Note: environment.d changes need a re-login to take effect."
fi

echo ">>> Configuration Complete!"
echo "    Please restart your terminal or run 'source ~/.zshrc' to apply changes."
