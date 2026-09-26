# Ghostty 配置

Linux 侧的 `config.ghostty` 有几处和上游写法不同：一处是 niri 这个会话环境逼出来的，
一处是 Linux 字体栈与 macOS 的差异（同样的写法在 macOS 上并不需要），还有一处是跟随
上游替换 deprecated 字段。macOS 的 `mac/.config/ghostty/config` 不受这些差异影响。
标题栏相关的部分见 `docs/ghostty-titlebar.md`。

## 中文字重：`font-codepoint-map` 与 Sarasa 缺失的 Medium

`font-style = Medium` 对 FiraMono 有效（它确实有 Medium face），但 Sarasa Mono SC 只有
XLight / Light / Regular / SemiBold / Bold，没有 Medium，fontconfig 会降级到 Regular：

```bash
fc-match "Sarasa Mono SC:style=Medium"   # -> Sarasa-Regular.ttc "Regular"
ghostty +show-face --string=A             # -> FiraMono Nerd Font Medium
ghostty +show-face --string=中            # -> Sarasa Mono SC
```

结果是中英混排时英文偏重、中文偏轻。用 `font-codepoint-map` 把 CJK 区段钉到
`Sarasa Mono SC SemiBold`：

```ini
font-codepoint-map = U+2460-U+24FF,U+2E80-U+9FFF,U+F900-U+FAFF,U+FE10-U+FE4F,U+FF00-U+FFEF=Sarasa Mono SC SemiBold
```

这是偏好取向，不是精确匹配。Sarasa 没有 Medium，只能在 Regular(400) 和 SemiBold(600)
之间二选一：两者与 FiraMono Medium(500) 的 `usWeightClass` 距离相同，而 fontconfig
weight 反而是 Regular(80) 更接近 Medium(100)（`fc-match -f '%{weight}'` 可直接查到）。
选 SemiBold 是为了中英混排时中文更醒目，代价是比英文略重；想更贴近英文的字重就把
上面那行的字体名换成 `Sarasa Mono SC`。

这里必须用 `font-codepoint-map`，不能靠重复 `font-family` 拼 fallback 链：fallback 列表里
的 family 会一起吃到全局的 `font-style = Medium`，而 codepoint-map 的字体值会原样交给
fontconfig，字重得以保留。验证：

```bash
ghostty +show-face --font-codepoint-map="U+4E2D=Sarasa Mono SC SemiBold" --string=中
# -> Sarasa Mono SC SemiBold
```

顺带把第三个 fallback 从比例字体 `Noto Sans CJK SC` 换成等宽的 `Noto Sans Mono CJK SC`，
避免比例字体参与终端渲染。macOS 不需要这一段：PingFang SC 自带 Medium，
`font-style = Medium` 在英文和中文上同时生效。

## quick terminal 的 global 绑定

上游配置里是：

```ini
keybind = global:ctrl+backquote=toggle_quick_terminal
```

`global:` 前缀要求 Ghostty 通过 XDG 门户的 `org.freedesktop.portal.GlobalShortcuts`
接口向桌面注册全局快捷键，而桌面侧要有后端实现它。本机装的是 `xdg-desktop-portal` +
`xdg-desktop-portal-gtk`，gtk 后端没有这个接口——当前会话暴露的接口列表里就没有
`GlobalShortcuts`：

```bash
busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop |
  grep -o 'org\.freedesktop\.portal\.[A-Za-z]*' | sort -u
```

所以这行在 niri 下只会注册失败。想恢复它得换一个实现了该接口的后端，目前能提供的是
`xdg-desktop-portal-hyprland`（本机未装，只在 Hyprland 会话里才有意义），换过去后把
上面那行加回 `config.ghostty` 即可。

niri 下想要「随手开一个终端」，用 niri 自己的绑定（`config.kdl`）：

| 绑定 | 行为 |
| --- | --- |
| `Mod+Return` | 普通新窗口 |
| `Mod+Shift+Return` | `~/.local/bin/niri-open-terminal-below`：在焦点窗口下方开一个 Ghostty |

后者是脚本而不是 Ghostty 特性：它先用 `niri msg --json event-stream` 等新窗口出现，再
对那个 window id 执行 `consume-or-expel-window-left`，所以不依赖固定 `sleep`、顺序稳定。

macOS 不涉及这条：`mac/.config/ghostty/config` 里保留了 `global:ctrl+backquote`，那边
的全局快捷键不走 XDG 门户。

## `bold-is-bright` → `bold-color = bright`

`bold-is-bright` 自 Ghostty 1.2.0 起 deprecated，文档给出的替代就是 `bold-color` 的
`bright` 用法：

```ini
bold-color = bright
```

语义一致：bold 文本使用 bright 调色板（终端用 OSC 4 改过的 palette 同样参与解析）。
实测 1.3.1 下两种写法的解析结果完全相同：

```bash
mkdir -p /tmp/gt-home/.config/ghostty
printf 'bold-is-bright = true\n' > /tmp/gt-home/.config/ghostty/config
HOME=/tmp/gt-home ghostty +show-config | grep bold   # -> bold-color = bright
```

注意 1.3.1 的 `+validate-config` 对 deprecated 字段是静默接受的，只有拼错的字段名才报
`unknown field`，所以这次替换在启动日志上没有任何区别，纯粹是跟随官方方向；旧写法也不
会刷警告，只是将来会被移除。
