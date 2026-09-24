# Announce this shell to the niri-windows module for Waybar.
#
# The module colours a window's tile by the CPU of the process tree behind it.
# That works per window as long as one window is one process, but a terminal
# that keeps every window in a single process (Ghostty's single-instance mode is
# the default in an Arch install) gives niri one pid for all of its windows, so
# a build in one window lights up every window of that terminal. niri has
# nothing finer to offer: a pid is all it knows about a window's process.
#
# A shell, however, knows that it runs in exactly one window: the window whose
# title its terminal shows. So the shell writes its pid into the title, in
# characters nothing renders, and the module (which reads titles from niri)
# measures that shell's tree for that window from then on. See module/marker.go
# for the encoding.
#
# Source this file at the end of ~/.zshrc, after anything else that sets the
# title, so that its write is the last one:
#
#     source /path/to/contrib/zsh-announce.zsh
#
# A window title is replaced as a whole, so the announcement has to be on a
# write the shell makes over and over: this file re-writes the title at every
# prompt. It writes the title the prompt itself would have written — oh-my-zsh
# and most themes publish that text in ZSH_THEME_TERM_TITLE_IDLE, and Ghostty's
# own format (the truncated working directory) is the fallback — so nothing
# about the visible title changes. Ghostty's shell integration can go on writing
# its title: this file's write comes after it and is the one that stays, so
# `shell-integration-features = ...,no-title` is only worth setting to save the
# duplicate write.
#
# Command titles are left alone. While a command runs there is no announcement
# in the title, and the module uses the pid this shell announced at the last
# prompt, which it remembers (see module/announcement.go).
#
# Anything else that owns a window's title can announce itself the same way, by
# appending the output of `_wnw_tag $$` to whatever it writes. Announcing is
# optional: a window that never announces anything keeps the behavior it had
# before, measured by the whole application's process tree.

# Unicode tag characters: default-ignorable, so no renderer shows them, and the
# module's grammar takes a decimal pid between U+E0001 and U+E007F.
typeset -ga _wnw_tag_digit=(
  $'\U000E0030' $'\U000E0031' $'\U000E0032' $'\U000E0033' $'\U000E0034'
  $'\U000E0035' $'\U000E0036' $'\U000E0037' $'\U000E0038' $'\U000E0039'
)

# _wnw_tag [pid]: the announcement for a pid (this shell's by default).
_wnw_tag() {
  local digits=${1:-$$} out=$'\U000E0001' i
  for (( i = 1; i <= ${#digits}; i++ )); do
    out+=$_wnw_tag_digit[${digits[i]}+1]
  done
  print -rn -- "$out"$'\U000E007F'
}

# This shell's announcement. A shell keeps its pid for its whole life, so it is
# built once. ($$ is the pid of the shell that started, not of a subshell, which
# is what a window's shell is.)
typeset -g _wnw_announcement=$(_wnw_tag $$)

# Where the title goes: the descriptor Ghostty's shell integration opened, or
# the terminal, or stdout if there is no terminal to open. Writing to the
# terminal rather than to fd 1 keeps the title out of a redirected stdout.
typeset -gi _wnw_fd=1
if [[ -n ${_ghostty_fd:-} ]]; then
  _wnw_fd=$_ghostty_fd
elif [[ -n ${TTY:-} && -w $TTY ]] && zmodload zsh/system 2>/dev/null; then
  sysopen -o cloexec -wu _wnw_fd -- "$TTY" 2>/dev/null || _wnw_fd=1
fi

# _wnw_title <text>: show <text> in the window title, followed by this shell's
# announcement. Control characters are dropped: a working directory is allowed
# to contain one, and it must not be able to end the escape sequence (a program
# running in the terminal could do that anyway, but this is not the place to
# hand it over).
_wnw_title() {
  builtin print -rnu $_wnw_fd -- $'\e]2;'"${1//[[:cntrl:]]}$_wnw_announcement"$'\a'
}

# _wnw_precmd: the title at every prompt, which is where the announcement comes
# from. The text is the idle title the prompt's own hook uses, so that a window
# is named the same whether or not this file is installed; a setup with no such
# variable gets Ghostty's format.
_wnw_precmd() {
  local text=${ZSH_THEME_TERM_TITLE_IDLE-'%(4~|…/%3~|%~)'}
  _wnw_title "${(%)text}"
}

# add-zsh-hook appends, so this runs after the hooks of a shell integration that
# was sourced before ~/.zshrc and after anything sourced earlier here. It also
# refuses to add a hook twice, so sourcing this file again is harmless.
autoload -Uz add-zsh-hook

# An earlier version of this file also rewrote the title before every command.
# Drop that hook, so that re-sourcing this file in a shell that already had the
# old version loaded leaves command titles alone too.
add-zsh-hook -d preexec _wnw_preexec

add-zsh-hook precmd _wnw_precmd
