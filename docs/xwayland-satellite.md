# xwayland-satellite

Linux 侧的 X11 支持走 niri 集成的 [xwayland-satellite](https://github.com/Supreeeme/xwayland-satellite)：
niri 自己建 X11 socket、导出 `$DISPLAY=:0`，第一个 X11 客户端连上时才按需 spawn 卫星，卫星再拉起
Xwayland。`linux/install.sh` 因此额外从 AUR 装 `xwayland-satellite-git` 盖住官方包。

这篇记录为什么、怎么验证、以及什么时候能拆掉。

## 症状

Steam 顶栏（商店 / 库 / 社区 / 好友）鼠标悬停时，下拉菜单**闪一下就消失**，来不及点进去。
库里的右键上下文菜单同理。Big Picture 模式不受影响（它不走这条 X11 弹窗路径）。

## 根因

Steam 客户端 UI 是 CEF 离屏渲染，它拉出来的下拉菜单是**独立的 X11 弹窗窗口**：
`_NET_WM_WINDOW_TYPE_POPUP_MENU`、`override_redirect=true`、带 `WM_HINTS input=True`、不带
`WM_TAKE_FOCUS`。

卫星把 X11 弹窗映射成 Wayland 的 `xdg_popup`，在**首次 configure** 时判断要不要给它焦点
（`src/server/event.rs` 的 `xdg_popup::Event::Configure`），判据是 `WindowAttributes::require_wm_focus()`：

```text
0.8.2-1        acquire_input_via_wm && !has_take_focus
add2795 (#494) !override_redirect && (has_take_focus || accepts_input)
```

（`acquire_input_via_wm` 在 0.8.2 里就来自 `WM_HINTS` 的 Input 位；#494 把它重命名为 `accepts_input`，
语义不变：Input 位缺失时按 true 处理。）

Steam 的弹窗 `override_redirect=true`、`input=True`、无 `WM_TAKE_FOCUS`：

- 0.8.2 → 判据为真 → 卫星在弹窗刚 map 出来时主动 `focus_window(popup)`；
- #494 之后 → `override_redirect` 直接否定 → 永远不会被 focus。

0.8.2 那一步把 X 输入焦点塞给刚出现的弹窗，Steam 侧随即关掉下拉菜单——看起来就是「闪一下就没了」。
判据在 2026-05 的 `3273a0f`（PR #397，为修 Unity 编辑器 Add Component 搜索框的输入）被改成上面那行的，
0.8.2 里就带着这个行为。

#494 同时改了另一半：真正需要焦点的窗口，如果声明了 `WM_TAKE_FOCUS`，卫星改发 ClientMessage
让客户端自己决定，而不是直接抢焦点。

## 为什么能确定是卫星

- 上游 issue [Supreeeme/xwayland-satellite#468](https://github.com/Supreeeme/xwayland-satellite/issues/468)：
  多人 bisect 到 `3273a0f`，在 niri / sway / umbriel 上复现，Hyprland 与 KDE（自带 XWayland，不经卫星）正常。
- niri 侧有 #4517 / #4535 / #4532 三份重复报告，都被标为 `not niri: xwayland-satellite`。
- Valve 侧由 2026-09 的 Steam 更新触发：[ValveSoftware/steam-for-linux#13566](https://github.com/ValveSoftware/steam-for-linux/issues/13566)。
- PR #494 的描述里直接贴了 Steam 弹窗的 `xwininfo` 与 `WM_HINTS`，结论就是 `override_redirect` 这条没被处理。

本机对应的观察：`~/.local/share/Steam/logs/cef_log.txt` 里弹窗出现的那一刻会有
`atom_cache.cc(229) Add _NET_WM_STATE_KEEP_ABOVE to kAtomsToCache`。

## 落地方式

`linux/install.sh` 从 AUR 装 `xwayland-satellite-git`（它 `provides` / `conflicts: xwayland-satellite`，
所以脚本先把官方包摘掉）。

- 官方 `extra` 停在 0.8.2-1（2026-07-22），打包仓库 `git log` 里没有重打包记录，修复只在 master 上。
- 拿 AUR `-git` 就不用在本仓库 vendor patch + 自己跑 makepkg 出包。
- 代价一：引入 `yay`，这是本仓库第一次依赖 AUR helper；没有 yay 时脚本只提示、不中断。
- 代价二：`-git` 跟随 master，上游后续改动会直接进来。**这是临时的**，见下节。

## 生效与验证

niri 是按需拉起的，换二进制**只需要换掉 X11 这一层**，不必重启会话：关掉 Steam 和其它 X11 应用，
杀掉旧卫星，niri 会在下一个 X11 客户端连上时用新二进制重新拉起。

```bash
# 现在是谁在跑、二进制是哪一个
pgrep -af "xwayland-satellite|Xwayland"
readlink /proc/<satellite-pid>/exe   # 期望 /usr/bin/xwayland-satellite，不带 "(deleted)"
sha256sum /proc/<satellite-pid>/exe /usr/bin/xwayland-satellite   # 两者应一致

# 杀掉旧卫星，再随手触发一次 spawn
kill <satellite-pid>
DISPLAY=:0 xprop -root _NET_SUPPORTING_WM_CHECK >/dev/null
```

0.8.2 之后上游新增了「日志写进 syslog」，所以可以直接抓弹窗创建事件核对 `override_redirect`：

```bash
journalctl --user -f | grep --line-buffered "new window"
```

悬停 Steam 顶栏时应能看到 `override_redirect: true` 的 `CreateNotifyEvent`，且菜单稳定停留。
0.8.2 上同样的操作会让这个弹窗一连上就被 `focus_window` 抢走焦点。

## 什么时候拆掉

`extra` 发布比 0.8.2 新的版本（也就是第一个含 #494 的 release）之后：

```bash
sudo pacman -S xwayland-satellite   # 换回官方包
```

然后删掉 `linux/install.sh` 里那段 AUR 安装，重跑 `linux/install.sh`。
