# chezmoi 迁移评估

> **方案已演进**：本文最初设想把配置合并进本仓库。后续改为**另建独立项目**
> `jwu/dotfiles` 作为 chezmoi 配置真源，本仓库与 `desktop-settings`、`pi-config`
> 一并收窄为脚本与工程仓库。当前方案见 `~/bin/dotfiles/README.md`。
> 本文保留，因为其中「边界划分」「模板化点」「`gh` 抢写 `git config`」「迁移阶段」
> 等分析对独立项目方案同样成立。

本文评估把 `linux/config.sh` / `mac/config.sh` 的**文件同步层**换成
[chezmoi](https://www.chezmoi.io/) 的路径。它是一份方案，不是已执行的变更；文中所有
命令都未在本仓库上运行过。

截至评估时：chezmoi `v2.72.2`（2026-09-13 发布），Arch `extra` 仓库即为
`2.72.2-1`，无需 AUR。上游仓库 `twpayne/chezmoi`，Go 编写，MIT。

## 为什么值得评估

现状机制是 `cp` 覆盖 + `backup_file()` 生成 `*.bak.<时间戳>`。这个机制有三个可量化的
代价：

1. **`.bak` 堆积**。`find ~ -maxdepth 4 -name "*.bak.*" | wc -l` 当前是 60。它只增不减，
   清理靠人工，且同名文件的多个备份无法区分哪个是当前生效状态的前一版。
2. **平台差异靠复制整份文件**。`linux/.zshrc` 与 `mac/.zshrc` 实测差 26 行，
   `linux/.config/starship.toml` 与 `mac/.config/starship.toml` 差 4 行。共同的 100 多行
   被维护了两遍，改一次要记得改两处。
3. **没有差异预览**。`cp` 是无条件覆盖，`chezmoi diff` 对应的能力不存在；`config.sh`
   只能靠 `.bak` 事后回滚。

另外 `common/` + `linux/` + `mac/` 这份「按平台分目录」的结构，本质上是同一个文件集合的
平台变体。chezmoi 的模板机制正是为此设计的：一份文件，按 `chezmoi.os` / `chezmoi.hostname`
分支。

## 边界：什么进 chezmoi，什么留在脚本

读 `linux/config.sh`（316 行）后，它的动作可以干净地切成两类。

### 进 chezmoi（纯家目录文件写入，约占 95%）

- `~/.config/` 下：`nvim/init.lua`、`neovide/config.toml`、`git/config`、
  `starship.toml`、`zellij/config.kdl`、`yazi/{yazi.toml,theme.toml}`、
  `gitui/theme.ron`、`glow/one-dark.json`、`ghostty/{config.ghostty,titlebar*.css}`、
  `alacritty/alacritty.toml`、`gtk-4.0/gtk.css`、`hypr/*`、`waybar/*`、
  `swaylock/{config,backgrounds/}`、`environment.d/fcitx5.conf`、
  `autostart/nm-applet.desktop`
- `~/.zshrc`、`~/.omnisharp/omnisharp.json`
- `~/.local/bin/{niri-lock,niri-clipboard-history,niri-open-terminal-below}`
- `~/.local/share/icons/**`（Rime 状态图 + 键盘布局图，见 `docs/ime-icons.md`）
- `~/.local/share/applications/neovide.desktop`

其中所有 `chmod +x` 由 chezmoi 的 `executable_` 文件名前缀自动处理，不需要脚本。

### 留在脚本（chezmoi 不覆盖的领域）

| 动作 | 现行位置 | 处置 |
| --- | --- | --- |
| `sudo sed /etc/vconsole.conf` 设 TTY 字体 | `linux/config.sh` TTY Font 段 | 保留 |
| `sudo modprobe drivetemp` + `tee /etc/modules-load.d/drivetemp.conf` | Waybar 段 | 保留（写 `/etc`） |
| CFFI `niri-windows.so` 的版本戳比对与重编译 | Waybar 段 | 保留（编译产物） |
| `rm -f ~/.config/waybar/scripts/nvme-temp.sh` | Waybar 段 | 一次性清理，可做成 `run_once_` |
| `bash desktop-settings/fcitx5/install-linux.sh` | 末尾 | 保留（跨仓库调用） |
| pacman 装包、`gcc -O2 -o gpu-watch`、装工具链 | `linux/install.sh` | 完全不动 |

chezmoi 的设计目标是家目录里的**文件**，它不接管 root 拥有的路径，也不装包。所以
`install.sh`（装机、装包、编译）和 `install-arch` 仓库与本方案无关。

## 目标源布局

源目录建议用 `~/bin/dotfiles`（配合 `chezmoi --source`），并单独建一个 `jwu/dotfiles`
远程仓库，而不是塞进 `configs`。理由：chezmoi 的 `chezmoi init --apply <user>` 快捷方式
要求仓库名是 `dotfiles`，新机器上一条命令即可落地。

```
dot_zshrc.tmpl                                  ← linux/.zshrc + mac/.zshrc 合并
dot_omnisharp/omnisharp.json                    ← common
dot_config/
  git/config.tmpl                               ← common/.gitconfig（见下节）
  nvim/init.lua                                 ← common
  neovide/config.toml                           ← common
  yazi/{yazi.toml,theme.toml}                   ← common
  gitui/theme.ron                               ← common
  glow/one-dark.json                            ← common
  starship.toml.tmpl                            ← linux/ + mac/ 合并
  zellij/config.kdl                             ← linux
  ghostty/config.ghostty                        ← linux
  ghostty/titlebar*.css                         ← linux
  alacritty/alacritty.toml                      ← linux
  gtk-4.0/gtk.css                               ← linux
  hypr/*                                        ← linux
  waybar/*                                      ← linux
  swaylock/config.tmpl                          ← linux（占位符改模板）
  swaylock/backgrounds/*.webp                    ← linux/backgrounds/
  environment.d/fcitx5.conf                     ← linux
  autostart/nm-applet.desktop                   ← linux
dot_local/
  bin/executable_niri-lock
  bin/executable_niri-clipboard-history
  bin/executable_niri-open-terminal-below
  share/icons/**                                ← linux/.local/share/icons/
  share/applications/neovide.desktop            ← linux/neovide.desktop
.chezmoiignore                                  ← 按 OS 排除
```

两处**路径重映射**要特别注意，源里的层级和目标层级不同，不能整体搬：

- `linux/backgrounds/*.webp` → `~/.config/swaylock/backgrounds/`
- `linux/neovide.desktop` → `~/.local/share/applications/neovide.desktop`

`common/` 这个概念在 chezmoi 源里直接消失：原本 `common` + `linux` + `mac` 三份，
塌缩成一份文件加模板分支。

## 需要模板化的四处

### 1. `.zshrc`（26 行差异，收益最大）

Linux 独有 7 处：`PI_NERD_FONTS`、`COLORTERM=truecolor`、`ZVM_INSTALL` 与两条 PATH、
以及末尾的 waybar announce（`source ~/.config/waybar/zsh-announce.zsh`，见
`docs/waybar.md`）。macOS 独有 brew 的 nvm 路径与 `/Applications/*` 的 neovide / zed
alias。模板结构大致：

```
{{ if eq .chezmoi.os "linux" }}
export ZVM_INSTALL="$HOME/.zvm/self"
export PATH="$PATH:$HOME/.zvm/bin"
[ -r ~/.config/waybar/zsh-announce.zsh ] && source ~/.config/waybar/zsh-announce.zsh
{{ else if eq .chezmoi.os "darwin" }}
[ -s "$(brew --prefix nvm)/nvm.sh" ] && source "$(brew --prefix nvm)/nvm.sh"
{{ end }}
```

waybar announce 那行必须在 `linux` 分支内，否则 macOS 上会去 source 不存在的文件。

### 2. `starship.toml`（4 行差异）

同样处理，差异小，属于顺手合并。

### 3. 两个 `sed` 占位符 → 原生模板

现在是手工替换，chezmoi 里是原生能力：

| 文件 | 现行写法 | chezmoi 写法 |
| --- | --- | --- |
| `waybar/modules.json` | `__WAYBAR_MODULE_DIR__` + `sed` | `{{ .chezmoi.homeDir }}/.config/waybar` |
| `swaylock/config` | `__SWAYLOCK_BACKGROUND_DIR__` + `sed` | `{{ .chezmoi.homeDir }}/.config/swaylock/backgrounds` |

两个占位符存在的原因是 waybar 的 `module_path` 和 swaylock 都不展开 `~`（见
`docs/waybar.md`、`docs/lockscreen.md`），必须有绝对路径。chezmoi 的 `homeDir` 正好提供
这个，且不再需要 `sed` 这一步。

### 4. ghostty 的目标文件名在两侧不同

Linux 是 `config.ghostty`，macOS 是 `config`。两个办法：

- **共享内容**：内容放 `.chezmoitemplates/ghostty-config`，两个目标文件各自
  `{{ template "ghostty-config" . }}`，各自的平台差异写在各自文件里。
- **统一命名**：两边都用 `config.ghostty`。Linux 侧已经在用这个扩展名，Ghostty 认它且
  编辑器有语法高亮。但 macOS 侧得先用 `ghostty +show-config` 验证该版本认这个文件名。

两侧内容实测差 2277 字节（Linux 7066、macOS 4789），差异不小，是否值得合并需要先看清
差异构成再定。

## 与 gh 抢 `~/.config/git/config`

实测家目录的 `~/.config/git/config` 和仓库的 `common/.gitconfig` **已经漂移**，家目录
多出一段由 `gh auth login` 自动写入的内容：

```
[credential "https://github.com"]
	helper =
	helper = !/home/jwu/.local/bin/gh auth git-credential
[credential "https://gist.github.com"]
	helper =
	helper = !/home/jwu/.local/bin/gh auth git-credential
```

这段是 `gh` 自己维护的，`gh auth login` / `gh auth setup-git` 都会改写这个文件。如果整个
文件交给 chezmoi 管，两个工具会互相覆盖：`chezmoi apply` 抹掉 helper，`gh auth login`
又被下一次 apply 抹掉。

推荐用 `[include]` 分离职责，chezmoi 管主干、gh 管本机段：

```ini
# dot_config/git/config.tmpl
[include]
	path = config.local
```

`~/.config/git/config.local` 不纳入 chezmoi，也不进远程仓库。注意本仓库现行做法是用 XDG
路径 `~/.config/git/config` 而**不是** `~/.gitconfig`，迁移时要保持这个选择，否则会意外
在 `~` 下创建 `~/.gitconfig`。

## 迁移阶段

每一步都可验证，且失败可回滚（现有仓库不动）。

### 阶段 0：装（不改任何现有文件）

```bash
sudo pacman -S chezmoi
```

### 阶段 1：从**家目录**导入，而不是从仓库导入

这是整个方案最关键的一步。导入源用家目录的当前状态，那么首次 `diff` / `apply` 必然是
空操作，**不存在覆盖风险**：

```bash
chezmoi --source ~/bin/dotfiles init
chezmoi --source ~/bin/dotfiles add ~/.zshrc ~/.config/starship.toml ...
chezmoi --source ~/bin/dotfiles diff      # 必须零输出 = 源即现状
```

### 阶段 2：与仓库对账，产出漂移清单

逐个比对源文件与 `linux/`、`mac/`、`common/` 中的副本：

```bash
diff ~/bin/dotfiles/dot_zshrc ~/bin/configs/linux/.zshrc
```

已知至少 1 处漂移（`~/.config/git/config` 对 `common/.gitconfig`）。这一步的价值在于找出
所有「手改过家目录但没回写仓库」的文件——**这些文件里可能有仓库版本没有的内容，直接以
仓库为准会丢东西**。

### 阶段 3：模板化，用渲染结果做等价性验证

```bash
chezmoi --source ~/bin/dotfiles execute-template < dot_zshrc.tmpl | diff - ~/.zshrc
```

输出为空即渲染等价，可以放心切换。

### 阶段 4：切换

`config.sh` 中所有 `cp` 段落替换为一处 `chezmoi apply`，非文件动作按上表保留。
`install.sh` 完全不动。

### 阶段 5：清理

`backup_file()` 机制退役，60 个 `*.bak.*` 一次性清掉。

## 风险

1. **首次 `apply` 的删除语义**。chezmoi 会移除源中不存在的受管文件。阶段 1 从家目录
   导入能规避这一点，但如果改成从仓库方向导入，必须先 `chezmoi -n -v apply` 干跑。
2. **`gh` 与 `~/.config/git/config` 的写入冲突**，见上节，必须先解决再纳入。
3. **`command -v X` 条件部署的行为变化**。`config.sh` 里大量 `if command -v
   ghostty/alacritty/zellij/yazi/gitui/glow/neovide/fcitx5` 的开关。chezmoi 部署配置文件
   不要求工具存在，建议改为无条件部署（工具没装时配置文件放着无害），或用
   `.chezmoiignore` 保留条件语义。**这是行为变化，要有意识地选**。
4. **Clink 运行时产物不能被收录**。`.gitignore` 里排除的 `win/clink_profile/*.txt`、
   `*_history*` 是运行期生成的历史文件，绝不能进 chezmoi 源，否则会互相覆盖历史。
5. **`win/` 本轮不纳入**。`.bat` 下载便携工具属于装机层，chezmoi 管不了。
6. **macOS 侧的 Ghostty 文件名与模板分支需要单独验证**，见上节。

## 待决策

以下是方案里必须由人拍板的点，未定之前不应开始阶段 1：

1. **源仓库**：新建 `jwu/dotfiles`（推荐，可用 `chezmoi init --apply jwu` 一条命令落地），
   还是在 `configs` 仓库内加一个源目录？
2. **`configs` 的最终形态**：迁移完成后 `common/`、`linux/`、`mac/` 三份结构是否退役，
   让本仓库退化为「`install.sh` + 系统层配置」？
3. **git config 策略**：用 `[include]` 分离（推荐），还是整文件交给 chezmoi 并接受
   `gh` 会改写它？
4. **范围**：`desktop-settings`（fcitx5 / Rime，文件与脚本混合）和 `pi-config` 是否一并
   纳入，还是本轮只做 `configs`？

## 参考

- 快速上手：<https://www.chezmoi.io/quick-start/>
- 源目录命名规则（`dot_` / `executable_` / `private_` / `symlink_` 前缀）与模板函数：
  <https://www.chezmoi.io/reference/>
- 与其它 dotfile 管理方式的对比：<https://www.chezmoi.io/comparison/>
