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
  "nautilus"
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

echo ">>> Installing/Updating packages via pacman: ${PACKAGES[*]}"
sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"

# ==========================================
# xwayland-satellite (AUR: carries upstream fix #494)
# ==========================================

# extra's xwayland-satellite 0.8.2-1 hands the X input focus to override-redirect
# popups on their first configure, so an X11 dropdown is dismissed the moment it
# appears: Steam's top bar (Store / Library / Community) and its context menus
# only flash. Upstream fixed the focus rules in #494 (commit add2795, 2026-09-09)
# but cut no release, and extra has not rebuilt since 0.8.2-1, so the fix only
# exists on master. The AUR -git package tracks master, which is the trade-off we
# accept here: drop this section once extra ships a release newer than 0.8.2.
# See docs/xwayland-satellite.md.
XWS_PKG="xwayland-satellite"
XWS_AUR_PKG="xwayland-satellite-git"

echo ">>> Installing $XWS_AUR_PKG (AUR)..."
if pacman -Q "$XWS_AUR_PKG" &> /dev/null; then
  echo "  Already installed: $(pacman -Q "$XWS_AUR_PKG")"
elif ! command -v yay &> /dev/null; then
  echo "  Note: yay is required to install $XWS_AUR_PKG; skipping. X11 menus under Steam will keep closing instantly."
else
  # The -git package provides/conflicts $XWS_PKG, so drop the repo package first
  # rather than let pacman hit its conflict prompt under --noconfirm.
  if pacman -Q "$XWS_PKG" &> /dev/null; then
    sudo pacman -R --noconfirm "$XWS_PKG"
  fi
  yay -S --needed --noconfirm "$XWS_AUR_PKG"
fi

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

if [ ! -f "$OH_MY_ZSH/themes/dracula.zsh-theme" ]; then
  TEMP_DIR=$(mktemp -d)
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

# Built from our fork of https://github.com/calico32/waybar-niri-windows
# (base: upstream v2.3.1 = 17828f9) because the fork carries fixes that are not
# upstream yet:
#   - title-only WindowOpenedOrChanged events no longer rebuild every tile, so a
#     program that animates its window title (a terminal spinner, ...) no longer
#     makes the tile under the cursor flicker
#   - PR #20: don't run state callbacks while holding the niri state lock
#     (waybar could deadlock and freeze permanently)
# Upstream ships a prebuilt x86_64 asset, but installing that would silently
# overwrite these patches, so we always build from source. Pinned to a commit:
# after pushing to the fork, bump WNMW_COMMIT and re-run this script.
# Window minimap CFFI module (wbcffi ABI v2), needs niri >= 25.08. See docs/waybar.md.
WNMW_REPO="https://github.com/jwu/waybar-niri-windows"
WNMW_COMMIT="66239ac27441dd835ac9f766c0607946820b997f"
WNMW_ASSET="waybar-niri-windows.so"
WNMW_DEST="$HOME/.config/waybar/$WNMW_ASSET"

# The stamped commit is the only reliable marker: the built .so is not
# reproducible byte-for-byte across Go / gtk3 versions.
wnmw_is_installed() {
  [ -f "$WNMW_DEST" ] || return 1
  [ "$(cat "$WNMW_DEST.version" 2>/dev/null)" = "$WNMW_COMMIT" ]
}

echo ">>> Installing Waybar niri-windows module (${WNMW_COMMIT:0:7})..."
if wnmw_is_installed; then
  echo "  Already installed, skipping."
else
  sudo pacman -S --needed --noconfirm go gcc make pkgconf gtk3 git
  WNMW_TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$WNMW_TMP_DIR"' EXIT
  mkdir -p "$WNMW_TMP_DIR/src"
  # Fetch exactly the pinned commit: a depth-1 clone of a branch would silently
  # follow the fork's branch instead of staying on the pinned revision.
  git -C "$WNMW_TMP_DIR/src" init -q
  git -C "$WNMW_TMP_DIR/src" remote add origin "$WNMW_REPO"
  git -C "$WNMW_TMP_DIR/src" fetch --depth 1 origin "$WNMW_COMMIT"
  git -C "$WNMW_TMP_DIR/src" checkout -q FETCH_HEAD
  make -C "$WNMW_TMP_DIR/src"
  mkdir -p "$HOME/.config/waybar"
  cp "$WNMW_TMP_DIR/src/$WNMW_ASSET" "$WNMW_DEST"
  printf '%s' "$WNMW_COMMIT" > "$WNMW_DEST.version"
  rm -rf "$WNMW_TMP_DIR"
  echo "  Built and installed to $WNMW_DEST"
fi

# ==========================================
# Copy Configurations
# ==========================================

bash "$SCRIPT_DIR/config.sh"
