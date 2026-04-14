#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BIN_DIR="$HOME/.local/bin"

echo ">>> Starting x86_64 installation setup..."
echo "    Root Config Dir: $ROOT_DIR"
echo "    Mac Settings Dir: $SCRIPT_DIR"
echo "    Architecture: x86_64 (Intel)"

mkdir -p "$BIN_DIR"

ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
  echo "Warning: Detected arm64 (Apple Silicon). This script is optimized for x86_64 (Intel) Macs."
elif [ "$ARCH" = "x86_64" ]; then
  echo "    Architecture verified: x86_64"
else
  echo "Warning: Unknown architecture: $ARCH"
fi

download_and_install() {
  local url=$1
  local dest=$2
  local temp_dir=$(mktemp -d)
  local filename=$(basename "$url")

  echo "  Downloading $filename..."
  curl -fsSL "$url" -o "$temp_dir/$filename"
  tar -xzf "$temp_dir/$filename" -C "$temp_dir"
  mv "$temp_dir"/*/"$dest" "$BIN_DIR/$dest" 2>/dev/null || mv "$temp_dir/$dest" "$BIN_DIR/$dest"
  chmod +x "$BIN_DIR/$dest"

  rm -rf "$temp_dir"
  echo "  Installed: $dest"
}

echo ">>> Installing CLI tools via curl..."

if ! command -v starship &> /dev/null; then
  echo "Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir "$BIN_DIR"
else
  echo "  starship already installed"
fi

if ! command -v zoxide &> /dev/null; then
  echo "Installing zoxide..."
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir "$BIN_DIR"
else
  echo "  zoxide already installed"
fi

if ! command -v fzf &> /dev/null; then
  echo "Installing fzf..."
  git clone --depth 1 https://github.com/junegunn/fzf.git /tmp/fzf
  /tmp/fzf/install --bin --no-update-rc --key-bindings --completion
  mv /tmp/fzf/bin/fzf "$BIN_DIR/fzf"
  rm -rf /tmp/fzf
else
  echo "  fzf already installed"
fi

if ! command -v eza &> /dev/null; then
  echo "Installing eza via Homebrew..."
  if command -v brew &> /dev/null; then
    brew install eza || brew upgrade eza
    ln -sf "$(brew --prefix)/bin/eza" "$BIN_DIR/eza"
  else
    echo "Error: Latest eza release does not provide a macOS x86_64 binary. Homebrew is required." >&2
    exit 1
  fi
else
  echo "  eza already installed"
fi

if ! command -v fd &> /dev/null; then
  echo "Installing fd via Homebrew..."
  if command -v brew &> /dev/null; then
    brew install fd || brew upgrade fd
    ln -sf "$(brew --prefix)/bin/fd" "$BIN_DIR/fd"
  else
    echo "Error: Latest fd release does not provide a macOS x86_64 binary. Homebrew is required." >&2
    exit 1
  fi
else
  echo "  fd already installed"
fi

if ! command -v bat &> /dev/null; then
  echo "Installing bat..."
  version="0.26.1"
  url="https://github.com/sharkdp/bat/releases/download/v${version}/bat-v${version}-x86_64-apple-darwin.tar.gz"
  download_and_install "$url" "bat"
else
  echo "  bat already installed"
fi

if ! command -v delta &> /dev/null; then
  echo "Installing delta via Homebrew..."
  if command -v brew &> /dev/null; then
    brew install git-delta || brew upgrade git-delta
    ln -sf "$(brew --prefix)/bin/delta" "$BIN_DIR/delta"
  else
    echo "Error: Latest delta release does not provide a macOS x86_64 binary. Homebrew is required." >&2
    exit 1
  fi
else
  echo "  delta already installed"
fi

if ! command -v rg &> /dev/null; then
  echo "Installing ripgrep..."
  version="15.1.0"
  url="https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version}-x86_64-apple-darwin.tar.gz"
  download_and_install "$url" "rg"
else
  echo "  ripgrep already installed"
fi

if ! command -v nvim &> /dev/null; then
  echo "Installing neovim..."
  version="v0.12.1"
  url="https://github.com/neovim/neovim/releases/download/${version}/nvim-macos-x86_64.tar.gz"
  temp_dir=$(mktemp -d)
  curl -fsSL "$url" -o "$temp_dir/nvim.tar.gz"
  tar -xzf "$temp_dir/nvim.tar.gz" -C "$temp_dir"
  cp "$temp_dir/nvim-macos-x86_64/bin/nvim" "$BIN_DIR/nvim"
  chmod +x "$BIN_DIR/nvim"
  [ ! -d "$HOME/.local/lib" ] && mkdir -p "$HOME/.local/lib"
  [ ! -d "$HOME/.local/share" ] && mkdir -p "$HOME/.local/share"
  cp -r "$temp_dir/nvim-macos-x86_64/lib/"* "$HOME/.local/lib/"
  cp -r "$temp_dir/nvim-macos-x86_64/share/"* "$HOME/.local/share/"
  rm -rf "$temp_dir"
else
  echo "  neovim already installed"
fi

export PATH="$BIN_DIR:$PATH"

echo ">>> Installing FiraMono Nerd Font..."

FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraMono.zip"
FONT_DIR="$HOME/Library/Fonts"
TEMP_DIR=$(mktemp -d)

curl -fsSL "$FONT_URL" -o "$TEMP_DIR/FiraMono.zip"
unzip -q "$TEMP_DIR/FiraMono.zip" -d "$TEMP_DIR"
cp "$TEMP_DIR"/*.otf "$FONT_DIR/" 2>/dev/null || true
rm -rf "$TEMP_DIR"

echo "  FiraMono Nerd Font installed"

echo ">>> Setting up Oh My Zsh..."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "  Oh My Zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo ">>> Installing zsh-autosuggestions..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
  cd "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && git pull && cd - > /dev/null
fi

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

backup_file() {
  if [ -f "$1" ]; then
    echo "  Backing up $1 to $1.bak.$TIMESTAMP"
    cp "$1" "$1.bak.$TIMESTAMP"
  fi
}

echo ">>> Copying configuration files..."

echo "Configuring WezTerm..."
backup_file "$HOME/.wezterm.lua"
cp "$ROOT_DIR/common/wezterm.lua" "$HOME/.wezterm.lua"

echo "Configuring EZA..."
mkdir -p "$HOME/.config/eza"

echo "Configuring Neovim..."
mkdir -p "$HOME/.config/nvim"
backup_file "$HOME/.config/nvim/init.lua"
cp "$ROOT_DIR/common/neovim.init.lua" "$HOME/.config/nvim/init.lua"

echo "Configuring Neovide..."
mkdir -p "$HOME/.config/neovide"
backup_file "$HOME/.config/neovide/config.toml"
cp "$ROOT_DIR/common/neovide.config.toml" "$HOME/.config/neovide/config.toml"

echo "Configuring Omnisharp..."
mkdir -p "$HOME/.omnisharp"
backup_file "$HOME/.omnisharp/omnisharp.json"
cp "$ROOT_DIR/common/omnisharp.json" "$HOME/.omnisharp/omnisharp.json"

echo "Configuring Starship..."
mkdir -p "$HOME/.config"
backup_file "$HOME/.config/starship.toml"
cp "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"

echo "Configuring .zshrc..."
backup_file "$HOME/.zshrc"
cp "$SCRIPT_DIR/zsh.zshrc" "$HOME/.zshrc"

echo "Configuring Git..."
mkdir -p "$HOME/.config/git"
backup_file "$HOME/.gitconfig"
cp "$ROOT_DIR/common/git.gitconfig" "$HOME/.gitconfig"

echo ""
echo ">>> x86_64 Installation Complete!"
echo ""
echo "    Make sure to add ~/.local/bin to your PATH:"
echo "      echo 'export PATH=\"~/.local/bin:\$PATH\"' >> ~/.zshrc"
echo ""
echo "    Installed CLI tools: starship, zoxide, neovim, fzf, eza, fd, bat, delta, ripgrep"
echo "    Installed Fonts: FiraCode"
echo "    Next Step:"
echo "        Please Manually Install GUI apps: WezTerm, Neovide"
