#!/bin/bash
set -uo pipefail

# ==========================================
# Configuration and Paths
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Waybar niri-windows module helpers (also sourced by config.sh).
source "$SCRIPT_DIR/waybar-niri-windows.sh"

FAILED_STEPS=()

echo ">>> Starting installation setup..."
echo "    Root Config Dir: $ROOT_DIR"
echo "    Linux Configs Dir: $SCRIPT_DIR"

# ==========================================
# Step runner
# ==========================================
#
# Every step runs to completion even when an earlier one failed. The network
# and the toolchain are the least predictable parts on a bare machine (the
# waybar module is fetched from GitHub and compiled), and a failed build used
# to abort the script before config.sh ran -- so every config file was silently
# left unsynced. Failures are now recorded, the run continues, and the summary
# at the end names what is missing while the exit code stays non-zero.

step() {
  local name="$1"
  shift
  local rc=0
  echo ""
  echo ">>> $name"
  "$@" || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "    ok"
  else
    FAILED_STEPS+=("$name")
    echo "    FAILED (exit $rc); continuing" >&2
  fi
}

summary() {
  echo ""
  echo "=========================================="
  if [ "${#FAILED_STEPS[@]}" -eq 0 ]; then
    echo ">>> All steps completed."
    return 0
  fi
  echo ">>> Finished with ${#FAILED_STEPS[@]} failed step(s):"
  local s
  for s in "${FAILED_STEPS[@]}"; do
    echo "      - $s"
  done
  echo ""
  echo "    These pieces are missing or stale. Re-run this script after fixing"
  echo "    them; it is idempotent and only redoes what is out of date."
  return 1
}

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
  "alacritty"
  "waybar"
  "swaylock"
  "swayidle"
  "hyprlock"
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
  "noto-fonts-emoji"
  "adwaita-fonts"
  "ttf-sarasa-gothic"
)

# A pacman transaction is atomic: one file that cannot be retrieved rolls the
# whole upgrade back and installs nothing, so every later step that needs these
# packages (zsh, fcitx5) fails too. The usual cause is the DB of the mirror that
# comes first in /etc/pacman.d/mirrorlist being a few hours behind: a package was
# rebuilt, that mirror still lists the old version, and the old file is already
# gone from every mirror (fcitx5 5.1.22 vs 5.1.23, 2026-09-25). Fix the
# mirrorlist first, then -Syy -- -Syy alone just re-reads the same stale mirror.
install_packages() {
  echo "    Installing/updating: ${PACKAGES[*]}"
  if sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"; then
    return 0
  fi
  echo "    pacman failed: a failed transaction installs no package at all." >&2
  echo "    A 404 on 'failed retrieving file' means the DB of the mirror listed" >&2
  echo "    first in /etc/pacman.d/mirrorlist is behind. Replace or reorder it," >&2
  echo "    e.g. 'sudo reflector --country China --age 6 --protocol https" >&2
  echo "    --latest 20 --sort rate --save /etc/pacman.d/mirrorlist', THEN run" >&2
  echo "    'sudo pacman -Syy' and re-run -- -Syy alone re-reads the same mirror." >&2
  return 1
}

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

install_xwayland_satellite() {
  echo "    Target: $XWS_AUR_PKG"
  if pacman -Q "$XWS_AUR_PKG" &> /dev/null; then
    echo "    Already installed: $(pacman -Q "$XWS_AUR_PKG")"
    return 0
  fi
  if ! command -v yay &> /dev/null; then
    echo "    yay is required to install $XWS_AUR_PKG; skipping (X11 menus under Steam keep closing instantly)." >&2
    return 1
  fi
  # The -git package provides/conflicts $XWS_PKG, so drop the repo package first
  # rather than let pacman hit its conflict prompt under --noconfirm.
  if pacman -Q "$XWS_PKG" &> /dev/null; then
    sudo pacman -R --noconfirm "$XWS_PKG" || return 1
  fi
  yay -S --needed --noconfirm "$XWS_AUR_PKG" || return 1
}

# ==========================================
# Zsh, Oh My Zsh, plugins and theme
# ==========================================

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# chsh rejects an empty -s argument with "shell must be a full path name", which
# says nothing about the real cause: zsh was never installed because the pacman
# step above failed. Check for it here instead of passing "" to chsh.
set_default_shell() {
  local zsh
  if ! zsh="$(command -v zsh)"; then
    echo "    zsh is not installed (see the pacman step above); skipping." >&2
    return 1
  fi
  if [ "${SHELL:-}" = "$zsh" ]; then
    echo "    zsh is already the default shell."
    return 0
  fi
  echo "    Changing default shell to zsh ($zsh)..."
  chsh -s "$zsh" || return 1
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "    Oh My Zsh is already installed."
    return 0
  fi
  echo "    Installing Oh My Zsh..."
  # Fetch first: `sh -c "$(curl ...)"` would swallow a failed download and run
  # an empty script, silently leaving Oh My Zsh uninstalled.
  local installer
  installer="$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || return 1
  sh -c "$installer" "" --unattended || return 1
}

install_zsh_autosuggestions() {
  local dest="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  if [ ! -d "$dest" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$dest" || return 1
  else
    echo "    already exists, pulling latest..."
    git -C "$dest" pull || echo "    pull skipped (local changes or no network)"
  fi
}

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
#   - window activity is measured per window: a shell announces its pid in the
#     window title (invisible tag characters), so the windows of a
#     single-instance terminal stop lighting up together. See docs/waybar.md.
# Upstream ships a prebuilt x86_64 asset, but installing that would silently
# overwrite these patches, so we always build from source. The revision is the
# fork's main HEAD, so pushing a fix to the fork is enough -- nothing here has
# to be bumped by hand. See linux/waybar-niri-windows.sh and docs/waybar.md.
# Window minimap CFFI module (wbcffi ABI v2), needs niri >= 25.08.

install_waybar_niri_windows() {
  local want
  want="$(wnmw_want_commit)"
  echo "    Target revision: ${want:0:7}"
  if wnmw_is_installed "$want"; then
    echo "    Already installed, skipping."
    return 0
  fi
  sudo pacman -S --needed --noconfirm go gcc make pkgconf gtk3 git || return 1
  wnmw_build_and_install "$want" || return 1
  echo "    Built and installed to $WNMW_DEST"
  wnmw_restart_hint
}

# ==========================================
# Waybar: NVIDIA GPU metrics (gpu-watch)
# ==========================================

# src/gpu-watch.c replaces scripts/gpu.sh, which spawned bash and nvidia-smi
# every two seconds: 16.8 ms of CPU per call, and with the usage and the
# temperature module both running that was 1.68% of one core, more than waybar
# itself uses. Almost all of it was nvidia-smi's startup, which a long-lived
# process pays once: the same two device queries in-process cost 0.017 ms.
#
# It opens libnvidia-ml with dlopen, so it needs no headers and links against
# nothing; gcc is the only build dependency. On a machine without the driver it
# prints the module's "off" line and exits, and waybar restarts it.
# See docs/waybar.md.

build_gpu_watch() {
  if ! command -v gcc &> /dev/null; then
    sudo pacman -S --needed --noconfirm gcc || return 1
  fi
  mkdir -p "$HOME/.local/bin"
  gcc -O2 -o "$HOME/.local/bin/gpu-watch" "$SCRIPT_DIR/src/gpu-watch.c" -ldl || return 1
  echo "    Installed to $HOME/.local/bin/gpu-watch"
}

# ==========================================
# Copy Configurations
# ==========================================

# config.sh also syncs the Fcitx5/Rime profile and theme from the sibling
# desktop-settings repo, so a successful run here is what makes Chinese input
# work without a separate manual step.
sync_configs() {
  bash "$SCRIPT_DIR/config.sh"
}

# ==========================================
# Run
# ==========================================

step "pacman packages" install_packages
step "xwayland-satellite-git (AUR)" install_xwayland_satellite
step "default shell (zsh)" set_default_shell
step "Oh My Zsh" install_oh_my_zsh
step "zsh-autosuggestions" install_zsh_autosuggestions
step "waybar niri-windows module" install_waybar_niri_windows
step "gpu-watch" build_gpu_watch
step "config sync (config.sh)" sync_configs

summary
