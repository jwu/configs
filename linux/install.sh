#!/bin/bash
set -euo pipefail

# ==========================================
# Configuration and Paths
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo ">>> Starting installation setup..."
echo "    Root Config Dir: $ROOT_DIR"
echo "    Linux Configs Dir: $SCRIPT_DIR"

# ==========================================
# Pacman Packages
# ==========================================

if ! command -v pacman &> /dev/null; then
  echo "Error: pacman is not available. Are you not on Arch Linux?"
  exit 1
fi

echo ">>> Installing/Updating packages via pacman..."
sudo pacman -Sy

PACKAGES=(
  "zsh"
  "starship"
  "zoxide"
  "neovim"
  "fzf"
  "eza"
  "fd"
  "bat"
  "git-delta"
  "terminus-font"
  "otf-firamono-nerd"
  "niri"
  "hyprland"
  "ghostty"
  "waybar"
  "swaylock"
  "swayidle"
  "fcitx5"
  "fcitx5-gtk"
  "fcitx5-qt"
  "fcitx5-rime"
  "fcitx5-configtool"
  "cliphist"
  "fuzzel"
  "wtype"
  "wl-clipboard"
  "noto-fonts-cjk"
  "ttf-sarasa-gothic"
)

echo "Installing packages: ${PACKAGES[*]}"
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# ==========================================
# Set Default Shell
# ==========================================

echo ">>> Setting zsh as default shell..."
if [ "$SHELL" != "$(command -v zsh)" ]; then
  echo "Changing default shell to zsh..."
  chsh -s "$(command -v zsh)"
else
  echo "zsh is already the default shell."
fi

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
  git -C "$ZSH_CUSTOM/plugins/zsh-autosuggestions" pull
fi

# ==========================================
# Theme: Dracula
# ==========================================

echo ">>> Installing Dracula Zsh Theme..."
OH_MY_ZSH="$HOME/.oh-my-zsh"
TEMP_DIR=$(mktemp -d)

if [ ! -f "$OH_MY_ZSH/themes/dracula.zsh-theme" ]; then
  curl -fsSL "https://github.com/dracula/zsh/archive/master.zip" -o "$TEMP_DIR/dracula.zip"
  bsdtar -xzf "$TEMP_DIR/dracula.zip" -C "$TEMP_DIR"
  cp "$TEMP_DIR/zsh-master/dracula.zsh-theme" "$OH_MY_ZSH/themes/dracula.zsh-theme"
  cp -r "$TEMP_DIR/zsh-master/lib" "$OH_MY_ZSH/themes/lib"
  rm -rf "$TEMP_DIR"
  echo "  Dracula Zsh Theme installed"
else
  echo "  Dracula Zsh Theme already installed"
fi

# ==========================================
# Waybar: niri window minimap (CFFI module)
# ==========================================

# https://github.com/calico32/waybar-niri-windows
# 图形模式小地图（CFFI 模块，wbcffi ABI v2），需要 niri >= 25.08。
# 上游只发 amd64 预编译包，所以下完先校 sha256 再落盘；
# 升级版本时同时改 WNMW_VERSION 和 WNMW_SHA256（取自同 tag 的 checksums.txt）。
WNMW_VERSION="v2.3.1"
WNMW_SHA256="6ae40a7ac277a1a46a823933213a5e0585b2c2a16374c225c66e17730304e533"
WNMW_ASSET="waybar-niri-windows.so"
WNMW_DEST="$HOME/.config/waybar/$WNMW_ASSET"

echo ">>> Installing Waybar niri-windows module ($WNMW_VERSION)..."
if [ -f "$WNMW_DEST" ] && echo "$WNMW_SHA256  $WNMW_DEST" | sha256sum -c --status -; then
  echo "  Already installed and checksum matches, skipping."
else
  mkdir -p "$HOME/.config/waybar"
  WNMW_TMP_DIR="$(mktemp -d)"
  curl -fsSL \
    "https://github.com/calico32/waybar-niri-windows/releases/download/$WNMW_VERSION/$WNMW_ASSET" \
    -o "$WNMW_TMP_DIR/$WNMW_ASSET"
  if ! echo "$WNMW_SHA256  $WNMW_TMP_DIR/$WNMW_ASSET" | sha256sum -c --status -; then
    echo "Error: sha256 mismatch for $WNMW_ASSET"
    rm -rf "$WNMW_TMP_DIR"
    exit 1
  fi
  cp "$WNMW_TMP_DIR/$WNMW_ASSET" "$WNMW_DEST"
  rm -rf "$WNMW_TMP_DIR"
  echo "  Installed to $WNMW_DEST"
fi

# ==========================================
# Copy Configurations
# ==========================================

bash "$SCRIPT_DIR/config.sh"
