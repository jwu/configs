#!/bin/bash
# Shared helpers for the patched niri window minimap CFFI module (our fork of
# calico32/waybar-niri-windows). Sourced by install.sh (fresh machine) and
# config.sh (existing machine); this file only defines variables and functions.
#
# The module is always built from source: upstream's prebuilt x86_64 asset would
# silently overwrite the fixes that live only on the fork. See docs/waybar.md.

WNMW_REPO="${WNMW_REPO:-https://github.com/jwu/waybar-niri-windows}"
WNMW_ASSET="waybar-niri-windows.so"
WNMW_DEST="${WNMW_DEST:-$HOME/.config/waybar/$WNMW_ASSET}"

# Used only when the fork cannot be reached (offline install). Bump alongside
# the last verified revision in docs/waybar.md.
WNMW_FALLBACK_COMMIT="c6dfc276341634ed042c9d56f70a7c7dc74f5b32"

# The revision to build is the fork's main HEAD, so pushing a fix to the fork is
# enough and nothing here has to be bumped by hand. Override for one build with
# `WNMW_COMMIT=<sha> ./install.sh`.
wnmw_want_commit() {
  if [ -n "${WNMW_COMMIT:-}" ]; then
    printf '%s\n' "$WNMW_COMMIT"
    return 0
  fi
  local head
  # Bounded wait: an unreachable GitHub must not stall config.sh for minutes.
  head="$(timeout 15 git ls-remote --exit-code "$WNMW_REPO" refs/heads/main 2>/dev/null | cut -f1 || true)"
  if [ -n "$head" ]; then
    printf '%s\n' "$head"
  else
    echo "    Note: cannot reach $WNMW_REPO, assuming ${WNMW_FALLBACK_COMMIT:0:7}" >&2
    printf '%s\n' "$WNMW_FALLBACK_COMMIT"
  fi
}

# The stamped commit is the only reliable marker: a .so is not reproducible
# byte-for-byte across Go / gtk3 versions, so a sha256 cannot be compared.
wnmw_stamp_commit() {
  cat "$WNMW_DEST.version" 2>/dev/null || true
}

wnmw_is_installed() {
  [ -n "${1:-}" ] || return 1
  [ -f "$WNMW_DEST" ] || return 1
  [ "$(wnmw_stamp_commit)" = "$1" ]
}

# Missing build tools, space separated. install.sh installs them via pacman when
# needed; config.sh only warns, because it must not sudo-install packages.
wnmw_missing_tools() {
  local tool missing=()
  for tool in go gcc make git; do
    command -v "$tool" > /dev/null 2>&1 || missing+=("$tool")
  done
  pkg-config --exists gtk+-3.0 2>/dev/null || missing+=("gtk3")
  printf '%s\n' "${missing[*]:-}"
}

wnmw_build_and_install() {
  local commit="$1"
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  mkdir -p "$tmp_dir/src"
  # Fetch exactly the resolved commit: a depth-1 clone of a branch would
  # silently follow the fork's branch instead of staying on that revision.
  if ! {
    git -C "$tmp_dir/src" init -q &&
      git -C "$tmp_dir/src" remote add origin "$WNMW_REPO" &&
      # The low-speed check aborts a dead connection instead of waiting for the
      # 5 minute HTTP timeout (the default behaviour, observed on 2026-09-24).
      git -C "$tmp_dir/src" -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 \
        fetch --depth 1 origin "$commit" &&
      git -C "$tmp_dir/src" checkout -q FETCH_HEAD &&
      make -C "$tmp_dir/src"
  }; then
    echo "    Error: build failed (network or toolchain?), keeping the installed module." >&2
    rm -rf "$tmp_dir"
    return 1
  fi
  mkdir -p "$(dirname "$WNMW_DEST")"
  # Install by rename, never by overwriting $WNMW_DEST in place: waybar has the
  # module mapped, and replacing the bytes it executes kills it within seconds
  # (SIGSEGV or SIGILL, plus a core dump). A rename swaps in a fresh inode and
  # keeps the old one alive for the running process. See docs/waybar.md.
  cp "$tmp_dir/src/$WNMW_ASSET" "$WNMW_DEST.new"
  mv -f "$WNMW_DEST.new" "$WNMW_DEST"
  printf '%s' "$commit" > "$WNMW_DEST.version"
  rm -rf "$tmp_dir"
}

wnmw_restart_hint() {
  echo "    waybar loads cffi modules only at startup, so restart it:"
  echo "      pkill -x waybar; sleep 1; setsid waybar >\"\$HOME/.cache/waybar.log\" 2>&1 &"
}
