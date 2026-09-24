# niri 配置

`linux/.config/niri/config.kdl` 里的输入与光标部分有几处和上游默认值不同，
起因是 `focus-follows-mouse` 这条规则的行为，下面记录推导过程。

## focus-follows-mouse 只在「跨进新窗口」时触发

niri 的 focus-follows-mouse 不是「指针在哪个窗口上就聚焦哪个」，而是「指针这次
移动从哪个窗口跨到了哪个窗口」。源码 `src/niri.rs` 的 `handle_focus_follows_mouse()`：

```rust
// 移动前的指针位置下的内容
let current_focus = self.contents_under(pointer.current_location());
...
if let Some(window) = &new_focus.window {
    if !self.layout.is_overview_open() && current_focus.window.as_ref() != Some(window) {
```

`new_focus` 是移动后的位置，`current_focus` 重新按移动前的位置算，两者窗口不同才
切换焦点。于是：

| 情况 | 结果 |
| --- | --- |
| 焦点在 a，指针已经停在 b 上，在 b 内部移动 | 前后都是 b → 不聚焦 |
| 指针移到 a（恰好是当前焦点窗口） | 前后不同 → 激活 a，无变化 |
| 指针从 a 移入 b | 前后不同 → 聚焦 b |

所以「指针先回到焦点窗口，再移到目标窗口」才能聚焦，直接动是不行的。

这是上游有意为之，不是配置错误。作者在 #2856 / #2078 的回复是：焦点跟随鼠标只在
指针移入新窗口时触发，其他合成器也这样，而且这样更不烦人。PR #2857 想删掉这个比较
被拒；社区要求的开关（对应 sway 的 `focus_follows_mouse = always`、Hyprland 的
`mouse_refocus`）目前 niri 没有。26.04 与 main 的这段逻辑一致。

`max-scroll-amount="25%"` 是另一层限制：即使触发了，要激活的窗口若会让工作区滚动
超过 25% 也照样放弃。

## warp-mouse-to-focus

用来绕开上面那条：焦点变化时把指针挪进焦点窗口，指针和焦点不再错位，下一次移动
就是正常的跨窗口，focus-follows-mouse 能正常触发。

niri 的焦点动作会调用 `maybe_warp_cursor_to_focus()`（`src/input/mod.rs`），
覆盖 `focus-column-*`、`focus-window-*`、`focus-workspace-*` 等，也就是键盘切焦点和
`niri msg action` 都会生效。三种模式（`src/niri.rs` 的 `CenterCoords`）：

| 配置 | 行为 |
| --- | --- |
| `warp-mouse-to-focus` | 指针在焦点窗口外才移动，且只调整越界的那一根轴 |
| `warp-mouse-to-focus mode="center-xy"` | 需要时把指针移到窗口中心 |
| `warp-mouse-to-focus mode="center-xy-always"` | 每次切换焦点都强行居中 |

两个已知不生效的场合：

- 键盘焦点在 layer shell 上（waybar、fuzzel 之类）时不 warp，
  `move_cursor_to_focused_tile()` 里有 `keyboard_focus.is_layout()` 判断。
- 新窗口自动弹出抢焦点不走 `State::focus_window()`，因此不 warp，那个场景仍然要
  点一下或者用一次键盘切焦点来同步。

## 光标隐藏

`cursor` 是顶层节点，两个开关都默认关闭：

```kdl
cursor {
    hide-when-typing
    hide-after-inactive-ms 2000
}
```

- `hide-when-typing`：打字时隐藏，指针一动或一点击就恢复。
- `hide-after-inactive-ms`：默认 `None`（永不隐藏），这里设成 2 秒。

niri 没有「手动隐藏光标」的 action 或 bind，这两个自动规则就是全部。

Ghostty 侧的 `mouse-hide-while-typing = true` 只覆盖它自己的窗口，niri 那条是全
会话生效的。另外 Ghostty ≥ 1.0.0 实现了 OSC 22 指针形状（用 CSS 光标名），程序可以
`\e]22;none\a` 隐藏、`\e]22;default\a` 恢复，适合在编辑器里临时藏起来，不属于常驻规则。
