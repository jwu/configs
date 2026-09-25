# Terminal Configs

开发环境配置方案 (Windows, Mac, Linux)。包含了 Alacritty, WezTerm, Neovim, Starship, Zsh 等工具的配置。

## Windows 配置方案

### 自动配置 (推荐)

此方案会自动下载便携版的工具到 `%USERPROFILE%\bin` 目录，并配置环境变量和配置文件链接。

1. 打开 CMD 或 PowerShell。
2. 克隆此仓库（建议路径）：
   ```cmd
   git clone https://github.com/jwu/configs.git %USERPROFILE%\bin\configs
   ```
3. 进入 `win` 目录：
   ```cmd
   cd %USERPROFILE%\bin\configs\win
   ```
4. 运行安装脚本（自动下载以下工具）：
   ```cmd
   install.bat
   ```

   安装的工具包括：
   - Alacritty v0.17.0 (终端模拟器)
   - Nerd Fonts (FiraMono) v3.4.0 (图标字体)
   - Clink v1.9.18 + clink-completions v0.6.8 (增强 CMD)
   - Starship v1.24.2 (终端提示符)
   - fzf 0.71.0 (模糊搜索)
   - zoxide 0.9.9 (智能目录跳转)
   - fd 10.4.2 (更快的 find)
   - bat 0.26.1 (更好的 cat)
   - delta 0.19.2 (更好的 diff)
   - ripgrep 15.1.0 (更快的 grep)
   - eza 0.23.4 (更好的 ls)
   - coreutils 0.8.0 (Unix 命令工具集)

5. 运行配置脚本（创建配置文件链接）：
   ```cmd
   config.bat
   ```

### 手动配置

如果你更喜欢手动安装工具，请参考以下步骤：

1. **安装工具**:
   - [Alacritty](https://github.com/alacritty/alacritty/releases) v0.17.0 (终端模拟器)
   - [Nerd Fonts (FiraMono)](https://www.nerdfonts.com/font-downloads) v3.4.0 (图标字体)
   - [Clink](https://github.com/chrisant996/clink) v1.9.18 (增强 CMD 体验)
   - [clink-completions](https://github.com/vladimir-kotikov/clink-completions) v0.6.8 (Clink 自动补全)
   - [Starship](https://starship.rs/) v1.24.2 (终端提示符)
   - [fzf](https://github.com/junegunn/fzf) 0.71.0 (模糊搜索)
   - [zoxide](https://github.com/ajeetdsouza/zoxide) 0.9.9 (智能目录跳转)
   - [fd](https://github.com/sharkdp/fd) 10.4.2 (更快的 find)
   - [bat](https://github.com/sharkdp/bat) 0.26.1 (更好的 cat)
   - [delta](https://github.com/dandavison/delta) 0.19.2 (更好的 diff)
   - [ripgrep](https://github.com/BurntSushi/ripgrep) 15.1.0 (更快的 grep)
   - [eza](https://github.com/eza-community/eza) 0.23.4 (更好的 ls)
   - [coreutils](https://github.com/uutils/coreutils) 0.8.0 (Unix 命令工具集)

2. **配置文件映射**:
   - **Alacritty**: 创建 `%APPDATA%\alacritty\alacritty.toml` 并引用 `win/alacritty.toml`。
   - **WezTerm**: 复制或链接 `common/.wezterm.lua` 到 `%USERPROFILE%\.wezterm.lua`。
   - **EZA**: 创建目录 `%USERPROFILE%\.config\eza`。
   - **Neovim**: 复制或链接 `common/.config/nvim/init.lua` 到 `%LOCALAPPDATA%\nvim\init.lua`。
   - **NeoVide**: 复制或链接 `common/.config/neovide/config.toml` 到 `%APPDATA%\neovide\config.toml`。
   - **OmniSharp**: 复制或链接 `common/.omnisharp/omnisharp.json` 到 `%USERPROFILE%\.omnisharp\omnisharp.json`。
   - **Clink**: 配置 Clink 加载 `win/clink_scripts` 中的脚本。

---

## Mac 配置方案

### 自动配置 (推荐)

脚本会自动安装 Homebrew 包，配置 Oh My Zsh，并链接配置文件。

1. 打开终端。
2. 克隆此仓库：
   ```bash
   git clone https://github.com/jwu/configs.git ~/bin/configs
   ```
3. 运行安装脚本：
   ```bash
   cd ~/bin/configs/mac
   ./install.sh
   ```

### 手动配置

1. **安装 Homebrew** (如果尚未安装):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **安装软件包**:
   ```bash
   # 命令行工具
   brew install starship zoxide neovim tree-sitter-cli fzf eza fd bat delta yazi gitui glow
   # GUI 应用
   brew install --cask neovide font-fira-mono-nerd-font
   ```

3. **配置 Shell (Zsh)**:
   - 安装 [Oh My Zsh](https://ohmyz.sh/)。
   - 安装插件 `zsh-autosuggestions`。
   - 参考或直接使用 `mac/.zshrc` 的内容替换 `~/.zshrc`。

4. **复制/链接配置文件**:
   - `common/.config/nvim/init.lua` -> `~/.config/nvim/init.lua`
   - `common/.config/neovide/config.toml` -> `~/.config/neovide/config.toml`
   - `common/.omnisharp/omnisharp.json` -> `~/.omnisharp/omnisharp.json`
   - `common/.gitconfig` -> `~/.config/git/config`
   - `mac/.config/ghostty/config` -> `~/.config/ghostty/config`
   - `mac/.config/starship.toml` -> `~/.config/starship.toml`
   - `common/.config/yazi/` -> `~/.config/yazi/`（`yazi.toml`、`theme.toml`）
   - `common/.config/gitui/theme.ron` -> `~/.config/gitui/theme.ron`
   - `common/.config/glow/one-dark.json` -> `~/.config/glow/one-dark.json`
   - `mac/.zshrc` -> `~/.zshrc`

   `mac/config.sh` 会按顺序完成以上复制，其中 yazi / gitui / glow 只在对应命令已安装时同步，git 配置写入 XDG 路径（`~/.config/git/config`），不会动 `~/.gitconfig` 里已有的身份信息。

---

## Linux 配置方案

### 自动配置 (Arch Linux / pacman)

> 如果机器上同时有 `configs` / `desktop-settings` / `pi-config` 三个仓库，推荐用顶层入口
> [`install-arch`](https://github.com/jwu/install-arch)：它会 clone/更新三者并逐个执行，
> 失败不阻断、最后汇总漏装项。下面的流程是它内部实际调用的一步。

当前 `linux/install.sh` 面向 Arch Linux / pacman 环境，会自动：
- 安装 `zsh`, `starship`, `zoxide`, `neovim`, `tree-sitter-cli`, `fzf`, `eza`, `fd`, `bat`, `git-delta`, `terminus-font` 和 `otf-firamono-nerd`
- 安装 Niri、Hyprland、Ghostty、Alacritty、Waybar、Swaylock、Swayidle、Fcitx5/Rime、Noto CJK、Noto Emoji 和 `ttf-sarasa-gothic` 字体
- 设置默认 shell 为 `zsh`
- 安装 Oh My Zsh、`zsh-autosuggestions`
- 运行 `linux/config.sh` 同步配置文件

使用方式：
```bash
cd ~/bin/configs/linux
./install.sh
```

### 手动配置

1. **安装工具**:
   使用你的发行版包管理器或参考官方文档安装：
   - `zsh`、`starship`、`zoxide`
   - `neovim`、`fzf`、`eza`、`fd`、`bat`、`git-delta`
   - 终端字体（Arch 下自动脚本使用 `terminus-font`）

2. **配置 Shell (Zsh)**:
   - 安装 [Oh My Zsh](https://ohmyz.sh/)。
   - 安装插件 `zsh-autosuggestions`。
   - 参考或直接使用 `linux/.zshrc` 的内容替换 `~/.zshrc`。

3. **复制/链接配置文件**:
   - `common/.config/nvim/init.lua` -> `~/.config/nvim/init.lua`
   - `common/.omnisharp/omnisharp.json` -> `~/.omnisharp/omnisharp.json`
   - `linux/.config/starship.toml` -> `~/.config/starship.toml`
   - `linux/.zshrc` -> `~/.zshrc`

4. **桌面与输入法配置**:
   - `linux/.config/niri/config.kdl` -> `~/.config/niri/config.kdl`
   - `linux/.config/hypr/hyprland.lua` -> `~/.config/hypr/hyprland.lua`
   - `linux/.config/ghostty/config.ghostty` -> `~/.config/ghostty/config.ghostty`
   - `linux/.config/alacritty/alacritty.toml` -> `~/.config/alacritty/alacritty.toml`（对齐 Ghostty 的主题/字体/键位，差异见文件末尾注释）
   - `linux/.config/waybar/` -> `~/.config/waybar/`（`config.jsonc`、`modules.json`、`style.css`、`colors.css`，以及 `scripts/` 下的 GPU / NVMe 取值脚本）
   - `linux/.config/environment.d/fcitx5.conf` -> `~/.config/environment.d/fcitx5.conf`
   - `linux/.local/share/icons/` -> `~/.local/share/icons/`（Fcitx5 托盘图标：`hicolor/scalable/apps/` 下三张 Rime 状态图，加 `Adwaita/symbolic/devices/input-keyboard-symbolic.svg`，见 `docs/ime-icons.md`）
   - 运行 `desktop-settings/fcitx5/install-linux.sh` 同步 Fcitx5、Rime 和候选窗主题

---

## 更新配置

仓库只保存配置源文件，`git pull` 之后需要重新同步到用户目录：

```bash
cd ~/bin/configs
git pull

# 按平台重新同步（覆盖同名文件，旧文件备份为 *.bak.<时间戳>）
bash mac/config.sh     # macOS
bash linux/config.sh   # Linux
cmd /c win\config.bat  # Windows
```

`install.sh` / `install.bat` 除了同步配置还会安装软件包或下载便携工具，日常更新只需要执行上面的 `config.sh` / `config.bat`。

Linux 侧 `config.sh` 还会顺手检查 Waybar 的 `cffi/niri-windows` 模块：它是我们 fork 的
`jwu/waybar-niri-windows` 从源码构建的产物，`.so.version` 与 fork main HEAD 不一致时会自动
重建（需要网络 + Go/gtk3 工具链，几分钟；工具链缺失则只提示）。细节见
[`docs/waybar.md`](docs/waybar.md)。

## Neovim + NeoVide 手动安装手册

### Windows

1. 安装 [nvim](https://neovim.io/)
1. 安装 [neovide](https://neovide.dev/)
  1. 先运行一下
1. 复制 `init.lua` 到 `c:\Users\${YOUR_NAME}\AppData\Local\nvim\init.lua`
1. 复制 `config.toml` 到 `c:\Users\${YOUR_NAME}\AppData\Roaming\neovide\config.toml`
1. 安装 [lazy.nvim](https://github.com/folke/lazy.nvim)
1. 安装 [rg](https://github.com/BurntSushi/ripgrep)
1. 安装 `fonts`
1. 编译 `nvim-treesitter` parsers
  1. 阅读 [MSVC](https://github.com/nvim-treesitter/nvim-treesitter/wiki/Windows-support#msvc) session
  1. 安装 [Visual Studio Build Tools](https://visualstudio.microsoft.com/zh-hans/downloads/?q=build+tools+for+visual+studio)
  1. 打开 `x64 Native Tools Command Prompt`
  1. 打开 `neovide`
  1. 输入 `:TSUpdate`
  1. 等待安装结束

### Linux

1. 安装 [nvim](https://neovim.io/)
  1. `sudo cp -r nvim-linux64/bin/ /usr/`
  1. `sudo cp -r nvim-linux64/lib/ /usr/`
  1. `sudo cp -r nvim-linux64/share/ /usr/`
1. 安装 [neovide](https://neovide.dev/)
  1. `sudo cp neovide-linux-x86_64/neovide /usr/bin/`
  1. 更新 ubuntu desktop
    1. `sudo desktop-file-install neovide.desktop`
    1. `sudo update-desktop-database`
1. 复制 `init.lua` 到 `~/.config/nvim`
1. 复制 `config.toml` 到 `~/.config/neovide`
1. 安装 [lazy.nvim](https://github.com/folke/lazy.nvim)
1. 安装 [rg](https://github.com/BurntSushi/ripgrep)
1. 安装 `fonts`
1. 编译 `nvim-treesitter` parsers

---

## Docs

以下文档记录了原先写在配置注释里的设计与踩坑：

- [`docs/waybar.md`](docs/waybar.md) — 模块基线与行高约定、配色、`cffi/niri-windows`、`module_path` 占位符。
- [`docs/ghostty.md`](docs/ghostty.md) — quick terminal 的 `global:` 绑定为何在 niri 下删掉、`bold-is-bright` → `bold-color` 的迁移。
- [`docs/ghostty-titlebar.md`](docs/ghostty-titlebar.md) — GTK 标题栏几何、undershoot 线、配色预设。
- [`docs/ghostty-gl-version.md`](docs/ghostty-gl-version.md) — Intel HD 4000 只到 GL 4.2 时，如何用 MESA override 保住硬件渲染、三个注入点与验证命令。
- [`docs/gtk4.md`](docs/gtk4.md) — GTK4 全局 CSD 直角微调。
- [`docs/bluetooth.md`](docs/bluetooth.md) — BlueZ OBEX agent 单槽位、blueman / bluetuith 冲突与诊断命令。
- [`docs/xwayland-satellite.md`](docs/xwayland-satellite.md) — X11 override-redirect 弹窗的焦点判据、Steam 顶栏菜单闪退、AUR `-git` 包的取舍与拆除条件。
- [`docs/ime-icons.md`](docs/ime-icons.md) — Fcitx5 托盘图标的同名覆盖规则（含键盘布局那张必须放 Adwaita 目录的原因）、SNI `IconName` 与状态的对应、大小写为何在 Wayland 下失效、重启 waybar 的时机。
- [`docs/niri.md`](docs/niri.md) — focus-follows-mouse 为何只在跨窗口时触发、`warp-mouse-to-focus` 的三种模式与不生效的场合、光标隐藏的两个开关。

源码注释保持简短，详细推导见以上文档。

---

## Reference

- Terminal
  - [WezTerm](https://wezterm.org/)
  - [alacritty](https://github.com/alacritty/alacritty)
  - [warp](https://www.warp.dev/)
  - Windows
    - [cmder](https://github.com/cmderdev/cmder)
    - [ConEmu](https://github.com/Maximus5/ConEmu)
    - [clink](https://github.com/chrisant996/clink)
      - [clink-completions](https://github.com/vladimir-kotikov/clink-completions)
      - [clink-fzf](https://github.com/chrisant996/clink-fzf)
      - [clink-zoxide](https://github.com/shunsambongi/clink-zoxide)
    - [git for windows](https://github.com/git-for-windows/git)
- Appearance
  - [Nerd Fonts](https://www.nerdfonts.com/)
  - [Dracula Theme](https://draculatheme.com/)
  - [starship](https://starship.rs/)
  - [tmux](https://github.com/tmux/tmux)
    - [zellij](https://zellij.dev/)
  - [vivid](https://github.com/sharkdp/vivid)
- Package Management
  - Windows
    - [winget](https://github.com/microsoft/winget-cli)
  - Mac
    - [homebrew](https://brew.sh/)
      - [zerobrew](https://github.com/lucasgelfond/zerobrew)
- utils (awesome)
  - [rg](https://github.com/BurntSushi/ripgrep)
  - [z](https://github.com/ajeetdsouza/zoxide)
  - [fzf](https://github.com/junegunn/fzf)
    - [skim](https://github.com/lotabout/skim)
  - [fd](https://github.com/sharkdp/fd)
  - [bat](https://github.com/sharkdp/bat)
  - [eza](https://github.com/eza-community/eza)
    - [lsd](https://github.com/Peltoche/lsd)
  - [coreutils](https://github.com/uutils/coreutils)
  - [dust](https://github.com/bootandy/dust)
  - [delta](https://github.com/dandavison/delta)
  - [sd](https://github.com/chmln/sd)
  - [procs](https://github.com/dalance/procs)
  - [zmx](https://github.com/neurosnap/zmx)
  - [glow](https://github.com/charmbracelet/glow)
  - [pass](https://www.passwordstore.org/)
    - [gopass](https://github.com/gopasspw/gopass)
- utils (tui)
  - [yazi](https://github.com/sxyazi/yazi)
  - [trippy](https://github.com/fujiapple852/trippy)
  - [bandwhich](https://github.com/imsnif/bandwhich)
  - [btm](https://github.com/ClementTsang/bottom)
    - [btop](https://github.com/aristocratos/btop)
    - [mactop](https://github.com/metaspartan/mactop)
    - [zenith](https://github.com/bvaisvil/zenith)
  - [xplr](https://github.com/sayanarijit/xplr)
  - [impala](https://github.com/pythops/impala)
  - [clashtui](https://github.com/JohanChane/clashtui)
  - [wiremix](https://github.com/tsowell/wiremix)
- utils (network)
  - [xh](https://github.com/ducaale/xh)
  - [rustscan](https://github.com/bee-san/RustScan)
- utils (media)
  - [yt-dlp](https://github.com/yt-dlp/yt-dlp)
  - [mpv](https://github.com/mpv-player/mpv)
  - [ffmpeg](https://www.ffmpeg.org/)
  - [chafa](https://github.com/hpjansson/chafa)
    - [viu](https://github.com/atanunq/viu)
  - [pngpaste](https://github.com/jcsalterego/pngpaste)
- utils (okay)
  - [s](https://github.com/zquestz/s)
  - [fanyi](https://github.com/afc163/fanyi)
- utils (shell)
  - zsh
    - [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh)
    - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
  - [nushell](https://github.com/nushell/nushell)
