# ------------------------------
# ghostty
# ------------------------------

if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
fi

# ------------------------------
# env vars
# ------------------------------

export PATH=~/bin:~/.local/bin:/usr/local/bin:$PATH
export ZSH=~/.oh-my-zsh
export EDITOR=nvim
export LANG=en_US.UTF-8
export STARSHIP_CONFIG=~/.config/starship.toml
export PI_NERD_FONTS=1

# ------------------------------
# zsh & oh-my-zsh
# ------------------------------

# ZSH_THEME="one-dark"

plugins=(
  git
)

source $ZSH/oh-my-zsh.sh
source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# ------------------------------
# fzf
# ------------------------------

source <(fzf --zsh)

# use fd instead of find for better performance
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# better ctrl-r
export FZF_DEFAULT_OPTS="
  --height 40% --layout=reverse
  --border --preview 'echo {}'
  --preview-window down:3:hidden:wrap
  --bind '?:toggle-preview'"

# better ctrl-t
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# ------------------------------
# eza alias
# ------------------------------

alias ls='eza'
alias ll='eza -lh --icons'
alias la='eza -lah --icons'
alias lt='eza --icons --tree'

# ------------------------------
# bat configs
# ------------------------------

export BAT_PAGER="less -RF"
export BAT_THEME="TwoDark"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ------------------------------
# mihomo proxy shortcuts
# ------------------------------

# proxy on
function pon() {
  # dfault is 7890, otherwise use arg1
  local port="${1:-7890}"
  export http_proxy="http://127.0.0.1:$port"
  export https_proxy="http://127.0.0.1:$port"
  export all_proxy="socks5://127.0.0.1:$port"
  echo "[Clash] Terminal Proxy ON (Port: $port)"
}

# proxy off
function poff() {
  unset http_proxy
  unset https_proxy
  unset all_proxy
  echo "[Clash] Terminal Proxy OFF"
}

# proxy status
function pstat() {
  echo "HTTP:  ${http_proxy:-Direct}"
  echo "HTTPS: ${https_proxy:-Direct}"
  echo "ALL:   ${all_proxy:-Direct}"
}

# ------------------------------
# dev envs
# ------------------------------

# ZVM
export ZVM_INSTALL="$HOME/.zvm/self"
export PATH="$PATH:$HOME/.zvm/bin"
export PATH="$PATH:$ZVM_INSTALL/"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# cargo
export PATH=~/.cargo/bin:$PATH

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# bun completions
[ -s "~/.bun/_bun" ] && source "~/.bun/_bun"

# opencode
export PATH=~/.opencode/bin:$PATH

# Android SDK
export PATH=~/Library/Android/sdk/platform-tools:$PATH
