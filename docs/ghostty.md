# Ghostty 配置

Linux 侧的 `config.ghostty` 有两处和上游写法不同，都是 niri 这个会话环境逼出来的；
macOS 的 `mac/.config/ghostty/config` 不受这些差异影响。标题栏相关的部分见
`docs/ghostty-titlebar.md`。

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
