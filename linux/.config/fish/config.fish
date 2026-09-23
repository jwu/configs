set -x PATH ~/bin ~/.cargo/bin ~/.local/bin /usr/local/bin $PATH
set -x PATH /opt/nvim-linux64/bin $PATH
set -x LANG "en_US.UTF-8"

# Define pyenv paths
set -gx PYENV_ROOT $HOME/.pyenv
set -gx PATH $PYENV_ROOT/bin $PATH

# Load pyenv
status --is-interactive; and . (pyenv init --path | psub)
status --is-interactive; and . (pyenv init - | psub)

# If you use pyenv virtualenv
status --is-interactive; and . (pyenv virtualenv-init - | psub)

starship init fish | source
zoxide init fish | source
