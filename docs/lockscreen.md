# 锁屏

Linux 侧锁屏统一走 `linux/.local/bin/niri-lock`：默认用 **hyprlock**；`hyprlock` 不在时回退
到 `swaylock`，这样锁屏不会因为缺包而静默失败。`Mod+L` 调用这个脚本。

## 熄屏

没有空闲自动锁屏：会话只在 `Mod+L` 时锁上。锁屏期间 `niri-lock` 自己拉起一个
`swayidle -w timeout 60`，空闲到点就 `niri msg action power-off-monitors`；swayidle 每次活动
后重新计时，所以只要还锁着，每段新的空闲都会再熄屏一次。计时器挂在锁屏进程的生命周期
上，解锁（锁屏进程退出）时 `trap ... EXIT` 杀掉它并点亮显示器 —— 熄屏倒计时从「锁上」
那一刻开始算，而不是从最后一次输入算。

点亮不需要额外机制：niri 收到按键/鼠标移动时自己激活显示器（`src/input/mod.rs` 的
`should_activate_monitors`），锁屏时它的 IPC 也照样接受 `PowerOffMonitors` /
`PowerOnMonitors`（同文件的 `allowed_when_locked`）。所以 niri 的 `spawn-at-startup` 里不再
有 swayidle。

`Mod+Alt+L` 那条恢复绑定直接跑 `swaylock -f`，绕过 `niri-lock`，那条路径没有熄屏计时。

## hyprlock 配置

`linux/.config/hypr/hyprlock.conf`（hyprlock 的默认搜索路径之一；`niri-lock` 仍显式传
`--config`）。基线是 [MrVivekRajan/Hyprlock-Styles] 的 **Style-10**，本地改了四处：

| 改动 | 原因 |
| --- | --- |
| `background.path` = swaylock 那张 `vantablack-1-twisted-stairs.webp` | 和 swaylock 观感一致；hyprlock 用 `absolutePath()` 展开 `~` |
| 删掉 Style-10 的头像 `image` | 没有头像；注释块留在文件里，指向自己的图即可启用 |
| 文字 `font_family` = `Adwaita Sans Bold`（原 `SF Pro Display Bold`） | 系统没装 SF Pro |
| 图标 label 用 `FiraMono Nerd Font Propo`（否则右边被切，见下） | 等宽 Nerd Font 的 advance 装不下图标 ink |

时间/日期走 `label { text = cmd[update:1000] ... }`，**本来就是实时的**。

## 装什么、拷什么

- `linux/install.sh` 的 `PACKAGES` 里有 `hyprlock`（`extra`）和 `adwaita-fonts`（星期/日期/
  时间那几行用 `Adwaita Sans Bold`）；图标字体的 `otf-firamono-nerd`、🔒 用的
  `noto-fonts-emoji` 本来就在列表里。
- `linux/config.sh`：把 `backgrounds/` 拷到 `~/.config/swaylock/backgrounds/`（swaylock 和
  hyprlock 共用，所以这段从 `command -v swaylock` 的 guard 里提出来了），再拷
  `.config/hypr/hyprlock.conf` 和 `.local/bin/niri-lock`。

## 图标右边被切掉（坑）

hyprgraphics 的 `TextResource.cpp` 按 **logical extents** 开纹理再画：

```cpp
cairo_image_surface_create(CAIRO_FORMAT_ARGB32, logical.width, logical.height);
cairo_move_to(CAIRO, -logical.x, -logical.y);
pango_cairo_show_layout(CAIRO, layout);
```

而等宽 `FiraMono Nerd Font` 给所有字形固定 0.8em 的 advance（50px 字号 = 40px），图标 ink
却更宽，于是右边一律被切：

| 字形 | ink | logical | 右边溢出 |
| --- | --- | --- | --- |
| `󰜉` mdi-restart | 46 | 40 | 6 |
| `󰐥` mdi-power | 45 | 40 | 5 |
| `󰤄` mdi-night | 45 | 40 | 5 |
| `` fa-user | 62 | 40 | 22 |

用**比例版** `FiraMono Nerd Font Propo` 后 advance 与 ink 基本一致（0-2px），且不引入额外
空白、不影响居中。换等宽字体里的任何图标都救不了（全都是同一个 0.8em advance）。

（`$USER` 那个 label 后面跟着空格和文字，溢出落在 logical 框内，所以看不出被切。）

## 背景能不能实时？

**不能是「桌面实时画面」**：`ext-session-lock` 期间 compositor 停止渲染原会话，没有帧可抓
（锁定时 `niri msg action screenshot-screen` 不产出文件，解锁后才产出）。所以 `background`
只能是静态图，`path = screenshot` 也只是锁定前那一下的截图 + 模糊。

能实时的是**锁屏客户端自己产出的内容**：`label` 的 `cmd[update:N]`，以及 `background`/`image`
的 `reload_time` + `reload_cmd`（重画一张 PNG 再让 hyprlock 重载）。要在锁屏上看窗口状态，
就是这条路：定时或按 niri 事件重跑渲染器 → `SIGUSR2` 让 hyprlock 重载；注意它上一张还
pending 时会 `Refusing to load`，刷新别太密。

## 恢复绑定

niri 里：

```
Mod+Alt+L allow-when-locked=true { spawn-sh "pkill -x hyprlock; pkill -x swaylock; sleep 0.3; swaylock -f"; }
```

`allow-when-locked` 让它在锁定时也能触发；杀掉卡死的 locker 后用最简单的 swaylock 接管。
锁屏客户端死掉时 niri 会留一个红屏（见 niri FAQ），这条绑定就是为那条路径准备的。

## 已知取舍

- hyprlock 锁定期间持续 ~60fps 重绘（GPU 加速），耗电比 swaylock 高。
- `--grace <sec>` **不要用**：niri 下 hyprlock 会收到一个 stray key 事件
  （`ERR: Invalid key down event (stray release event?)`），而 grace 期间任何输入直接解锁，
  实测 4 秒就自己解开了。
- 底部三个 `onclick`（`reboot now` / `shutdown now` / `systemctl suspend`）能否生效取决于
  polkit agent。

[MrVivekRajan/Hyprlock-Styles]: https://github.com/MrVivekRajan/Hyprlock-Styles
