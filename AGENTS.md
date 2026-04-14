# AGENTS.md

## Project

This repo is a cross-platform terminal/dotfiles setup for Windows, macOS, and Linux.

It is **not** an application and has **no build system**. Most work here is:
- updating install scripts
- adjusting config files
- fixing download/package references
- keeping platform-specific setup in sync

## Key structure

Only remember these entry points:
- `win/install.bat` — Windows tool installer with hardcoded versions / URLs
- `win/config.bat` — Windows config/link setup
- `mac/install.sh` — primary macOS installer (Homebrew-based)
- `mac/install_x86_64.sh` — Intel Mac fallback installer
- `linux/install.sh` / `linux/config.sh` — Linux install/config scripts
- `common/` — shared configs used by multiple platforms

Useful shared configs:
- `common/wezterm.lua`
- `common/neovim.init.lua`
- `common/neovide.config.toml`
- `common/git.gitconfig`

## Working rules

- Make **small, targeted changes**.
- Prefer updating existing scripts/patterns over introducing new structure.
- Keep scripts **idempotent** and safe to re-run.
- Do not invent file names or workflows; check the repo first.
- When updating versions, also verify the corresponding package name or asset URL still exists.

## Validation

Run the smallest relevant validation only.

### Shell syntax
```bash
bash -n mac/install.sh
bash -n mac/install_x86_64.sh
bash -n linux/install.sh
bash -n linux/config.sh
```

### Batch validation
```powershell
batchlint win/install.bat
batchlint win/config.bat
```

### ShellCheck
```bash
shellcheck mac/install.sh
shellcheck mac/install_x86_64.sh
shellcheck linux/install.sh
shellcheck linux/config.sh
```

### Homebrew checks
When editing `mac/install.sh`, verify package/cask names:

```bash
brew info --formula starship zoxide neovim fzf eza fd bat git-delta
brew info --cask wezterm@nightly alacritty neovide font-fira-mono-nerd-font
```

### Download URL checks
When editing hardcoded release URLs, verify they are downloadable:

```bash
curl -I -L <url>
```

For GitHub releases, prefer checking the latest release/API before changing version constants.

## Platform-specific guidance

### Windows
- `win/install.bat` is version-sensitive.
- Some assets are not simple version templates.
- `CLINK_URL` is a full asset URL with a build suffix; verify the exact asset name.
- After changing versions, check every download URL.

### macOS
- `mac/install.sh` is the main path.
- `wezterm@nightly` is the current validated cask name.
- On Intel Macs, upstream projects may stop publishing latest `x86_64-apple-darwin` assets; if so, prefer Homebrew over pinning an old release.

### Linux
- Use the existing `linux/install.sh` and `linux/config.sh` flow.
- Prefer package-manager-friendly and repeatable changes.

## Safety

Safe to do without asking:
- read/search files
- small edits to scripts/configs
- syntax checks
- local validation like `bash -n`, `shellcheck`, `batchlint`, `brew info`, URL HEAD checks

Ask before:
- deleting files
- large refactors or repo-wide rewrites
- adding new dependencies/tools without clear need
- changing install behavior in a way that breaks existing users
- running destructive commands

## Preferred patterns

- Bash: prefer `#!/bin/bash` + `set -euo pipefail`
- Batch: use `setlocal enabledelayedexpansion`
- Use clear progress output like `>>> ...`
- Quote variables properly
- Prefer symlinks on Unix-like systems when the script already follows that pattern
- Prefer copying/linking from existing files in `common/`, `mac/`, `linux/`, `win/`

## References

When making changes, these are usually the best files to copy patterns from:
- Windows installer logic: `win/install.bat`
- macOS Homebrew flow: `mac/install.sh`
- Intel macOS direct-download logic: `mac/install_x86_64.sh`
- Linux config/install flow: `linux/install.sh`, `linux/config.sh`

## When stuck

Do not guess.
- inspect the real file structure
- check the current script before editing
- verify package names / asset URLs
- if a change has multiple plausible directions, ask first
