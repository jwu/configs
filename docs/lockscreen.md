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

样式拆成三份文件，都在 `linux/.config/hypr/`：

| 文件 | 作用 |
| --- | --- |
| `hyprlock-small.conf` | 紧凑样式，按 480x320 设计：只留时间 + 一个毛玻璃密码框 |
| `hyprlock-large.conf` | 完整 [Style-10][MrVivekRajan/Hyprlock-Styles]，按 2560x1440 设计 |
| `hyprlock.conf` | 只有一行 `source`，指向 small —— 给裸跑 `hyprlock` 一个默认 |

三份文件里**所有 widget 的 `monitor` 都留空**，也就是“整份文件作用于当前所有显示器”。
挑哪一份是 `niri-lock` 在锁屏前做的：`niri msg outputs` 的文本输出里只要有哪块屏的
`Logical size` 宽度 ≥ 900 就用 large，否则 small（拿不到输出信息时也退回 small）。阈值写在
`niri-lock` 的 `WIDE_MIN_WIDTH`。

时间/日期走 `label { text = cmd[update:1000] ... }`，**本来就是实时的**。

### 为什么按样式分文件，而不是在配置里按显示器写

hyprlock 的 `font_size` / `position` / `size` **全是绝对像素**，没有 `em`、百分比或任何
响应式单位；而 `monitor` 只做字符串匹配 —— 精确等于端口名，或匹配 EDID 描述前缀，
**分辨率完全不参与匹配**：

```cpp
// src/renderer/Renderer.cpp -- widget 与显示器的匹配条件
if (!c.monitor.empty()
    && c.monitor != POUTPUT->stringPort
    && !POUTPUT->stringDesc.starts_with(c.monitor)
    && !("desc:" + POUTPUT->stringDesc).starts_with(c.monitor))
    continue;
```

`COutput` 手里就有分辨率（`Vector2D size`），但这个条件一次都没用上。它也不支持逗号
列表、通配符、正则，更没有「默认/兜底」语义：`monitor =` 留空表示**所有**显示器，表达
不了「除了上面提过的之外」。后果是三条一起成立的：

- 一套数值不可能同时适配 480x320 和 2560x1440（旧的单套值按 ~1920x1080 写，`font_size=90`
  的星期标签在 480 宽的屏上几乎占满，`position=0,350` 的偏移把文字推出屏幕，`x=820` 的
  电源按钮在 480 宽上完全不可见）；
- 想让某块屏不叠加另一套布局，两块屏就必须各自点名 `monitor`，于是配置和硬件绑死：换
  HDMI 口（`HDMI-A-3` → `HDMI-A-2`）匹配就失效、那块屏变黑；
- **没被点名的显示器，在那块屏上一个 widget 都不会画（黑屏）**。但密码仍能盲打解锁 ——
  认证在 session lock 层，与有没有 input-field 组件无关。

`monitor =` 留空 = 作用于所有显示器，这条规则反过来给了出路：**把选择挪到文件层面**。
每份文件整体就是一个样式，内部全部留空，由 niri-lock 按当前最宽的屏挑一份。文件本身
就是声明，配置里不再出现端口名。

hyprlock 的 `source` 不能用来做条件选择（`handleSource` 走的是 `glob()`，只认 `~` 和通配
符，不展开其它环境变量），所以选择只能在锁屏脚本里做。`hyprlock.conf` 保留一行
`source`，是为了让裸跑 `hyprlock` 也有内容，而不是读到空配置。

**取舍**：两块屏同时插着时只有一份样式生效，另一块屏不会有 widget。只要两块屏同时在线
又需要不同布局，就只能在同一个文件里按名字区分 —— 这是上面那个 `if` 决定的。当前假设
是「基本不会同时插」。

（也试过用 `hyprlock.conf.tmpl` + 生成脚本在锁屏前按分辨率拼配置，能覆盖多屏并存的情况，
但链路太长（模板 / 生成器 / niri-lock 三处协作），已经 revert。git 历史里有完整实现。）

### 小屏布局（480x320）

屏幕中心 `(240, 160)`，**`position` 的 y 正向朝上**（`posFromHVAlign` 里 `valign=top`
对应大 y），`valign` 决定锚点在底/中/顶：

| 元素 | 几何 | 位置（从屏顶算） |
| --- | --- | --- |
| 毛玻璃板 | 320x130 | 69-199 |
| 时间 | 60px | 中心 134 |
| 密码输入框 | 300x50 | 218-268 |

时间背后的板是 `shape`（白 7% + 1px 白边 10%）。输入框与大屏那款同形：`inner_color` 白
10% 加 `🔒 Enter Pass` 提示，一眼能看出往哪打字。两者间距 19px，顶部留白 69px、底部留白
52px；输入框字号由 `size.y / 4` 推导（50/4 ≈ 12px），提示文字和失败信息都不会撑破布局。

### 背景是实测对比度挑的，不是按比例挑的

时间文字是 `rgba(226,232,240)`，WCAG AA 要求对比度 ≥ 4.5:1。按 hyprlock 的实际处理链
（`gain()` 曲线 + 模糊）算出来的时间区结果：

| 壁纸 | 比例 | 时间区背景均值 | 对比度 |
| --- | --- | --- | --- |
| `ristretto-0-launch` | 1.50（与小屏一致，零裁剪） | RGB(94,51,24) | **8.7:1** ✓ |
| `vantablack-1-twisted-stairs` | 1.78（大屏上下裁 7.8%） | RGB(19,19,19) | **15.1:1** ✓ |
| `ristretto-1-color-curves` | 1.78 | RGB(177,124,70) | 2.9:1 ✗ |
| `osaka-jade-3-mountain-moon` | 1.78 | RGB(154,202,148) | 1.5:1 ✗ |

**不要按宽高比自动挑图**：`osaka-jade` 的 1.78 正好匹配大屏，但白字对比度只有 1.5:1，
挑中它直接看不清。大屏用的是对比度最高的那张。

大屏试过换成小屏那张暖橙图，但大屏文字是**大字号配 0.70 透明度**，叠在偏亮的暖橙上有效
对比度只剩约 3.2:1 —— 刚过 AA 大文本的 3:1，够不到 4.5:1。而 hyprlock 没有「压暗背景」
的手段：

- `background` 的 `brightness` **只在 `> 1.0` 时**参与乘法
  （`Shaders.hpp` 的 `FRAGBLURPREPARE`：`if (brightness > 1.0) pixColor.rgb *= brightness;`），
  所以 `< 1.0` 的值是彻底的空操作。旧配置里从上游抄来的 `brightness = 0.8172` 从未生效，
  已经删掉。
- `background` 的 `color` 只是**纹理加载失败时的兜底色**，不与图混合。
- 用一层半透明黑色 `shape` 当遮罩也不行：widget 排序用的是 `std::ranges::sort`（不是
  stable sort），同 `zindex` 的相对顺序没有保证，遮罩会随机盖住文字。

顺带记一笔：`contrast` / `brightness` / `vibrancy` **只在 `blur_passes > 0` 时**才被应用。

### 大屏那套只改了一处

字号与间距全部保留 Style-10 原值（90/40/20、350/250/190）。唯一改动是底部三个按钮的
定位：原来用 `halign=left/right` 配 `x=±820`，那是照 1920 宽写死的，屏一宽就挤到中间偏
左；现在三个统一 `halign=center`、只差 x 偏移（±160），任何宽度下都在底部居中且等距。

`onclick` 也从 `reboot now` / `shutdown now` 换成了 `systemctl reboot` / `poweroff` ——
前者在 Arch 上并不存在。

其它沿用的本地改动：文字 `font_family` 用 `Adwaita Sans Bold`（上游是没装的
`SF Pro Display Bold`）；图标 label 用 `FiraMono Nerd Font Propo`（原因见下节）；
Style-10 的头像 `image` 已删掉（没有头像，注释块也一并删了）。

### 其它坑

- **`#` 要写两遍**：hyprlang 把裸 `#` 当行内注释起始，所以 Pango 标记里的颜色要写
  `##ff8a80`（`placeholder_text` 里的 `##ffffff99` 同理）。
- **`fail_text` 用 `$ATTEMPTS` 而不是 `$FAIL`**：后者是 `g_pAuth->getCurrentFailText()`，
  即 PAM 的原始错误文字，太长；`$ATTEMPTS` 才是失败次数。
- **`fail_text` 的字号**由 `size.y / 4` 推导（小屏 46/4 ≈ 11px），不会撑破布局。
- **没有 `fail_transition` 这个参数**：v0.9.6 的 `ConfigManager.cpp` 里没有注册它（失败
  过渡由 animation 的 `inputFieldColors` 节点控制）。

## 装什么、拷什么

- `linux/install.sh` 的 `PACKAGES` 里有 `hyprlock`（`extra`）和 `adwaita-fonts`（星期/日期/
  时间那几行用 `Adwaita Sans Bold`）；图标字体的 `otf-firamono-nerd`、🔒 用的
  `noto-fonts-emoji` 本来就在列表里。
- `linux/config.sh`：把 `backgrounds/` 拷到 `~/.config/swaylock/backgrounds/`（swaylock 和
  hyprlock 共用，所以这段从 `command -v swaylock` 的 guard 里提出来了），再拷
  `.config/hypr/hyprlock{,-small,-large}.conf` 和 `.local/bin/niri-lock`。

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
- 底部三个 `onclick`（`systemctl suspend` / `reboot` / `poweroff`）能否生效取决于 polkit agent。

[MrVivekRajan/Hyprlock-Styles]: https://github.com/MrVivekRajan/Hyprlock-Styles
