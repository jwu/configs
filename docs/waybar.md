# Waybar

Linux 侧 Waybar 配置位于 `linux/.config/waybar/`：`config.jsonc`、`modules.json`、
`style.css`、`colors.css`，以及 `scripts/` 下的取值脚本。

## 基线与行高

Waybar（GTK3）会把每个模块的 label 放进独立格子做垂直居中，label 的行高取决于它内容里
最高的字形。一个含 20px 铭牌的模块挨着一个只有 16px 文字的模块，基线就会差约 1~1.5px。

做法：所有模块的 `format` 前面都放两段零宽撑高 span（U+200B，不占宽度）：

```
<span size='15pt'>\u200b</span>               把 ascent 撑到 18.7px
<span size='15pt' rise='-1536'>\u200b</span>  把 descent 撑到 7.3px
```

这样每个 line box 都是 18.7 + 7.3 = 26px，且 ascent 相同，基线才一致。

铭牌本身再下移 2px（`rise='-1536'`），让框的中心与数字中心重合：15pt 框字原本在基线上方
15px、下方 1px，下移 2px 后上下各 3px，正好居中。

`20px = 15pt`：Pango markup 的 `size` 只认 pt/%/关键字，不认 px。tray / privacy 模块走
的是像素值 `icon-size`。

例外：`#clock` 里的中文「月日」字形行高更高、ascent 也不同，会整体低约 0.7px，用
`#clock { margin-bottom: 1px }` 提回来（GTK3 的 margin 只产生约一半位移）。

## Workspace 按钮

Waybar 只加载用户这一份样式表（见 `src/client.cpp`），它自带的默认样式
`#workspaces button { background-color: transparent }` 不会生效，于是 Adwaita 的 button
样式会漏进来。`background: transparent` 能清掉渐变，但清不掉那 1px 近白描边，所以还必须
写 `border: none`。

## 用量与温度配色

低负载绿、告警黄、危急红。阈值在 `modules.json` 的 `states`；`custom/gpu` 的阈值写在
`scripts/gpu.sh`，`custom/gpu-temp` 和 `custom-ssd` 在各自脚本里。

温度模块的 padding 让读数紧贴所属组件，读起来是一组：`CPU 4% 31°C / GPU 11% 40°C`。

## bluetooth

`modules-right` 里排在 `network` 和 `pulseaudio#microphone` 之间（network 的图标在 IP 后面，
所以蓝牙落在网口图标右侧、麦克风左侧）。format 走上面的撑高约定，图标是 14pt 铭牌。

左键 `ghostty -e bluetuith`，右键 `bluetoothctl power toggle`。图标和颜色都按状态切——状态是
模块自己加到 widget 上的 CSS 类（源码里是 `update_style_context(state, true)`）：

| state | 触发条件 | 图标 | 颜色 |
| --- | --- | --- | --- |
| `on` | 适配器已开、无连接 | 󰂯 | 默认前景色 |
| `connected` | 至少 1 个设备已连接 | 󰂱 | `@color4` |
| `off` | 适配器 `Powered=false` | 󰂲 | `@color1` |
| `disabled` | 被 rfkill 屏蔽 | 󰂲 | `@color1` |
| `no-controller` | 系统没有适配器 | 󰂲 | 默认前景色 |

`format-icons` 写成对象时按 state 取，取不到才回退 `default`（`ALabel::getIcon`），所以每个
state 都显式写了键。

`#bluetooth` 必须待在 `color: @ghostty_fg` 那个选择器列表里。漏掉的话它会用 GTK 默认前景色
`#2e3436`，叠在 `@ghostty_bg`（`#282c34`）上肉眼等于隐形——实测该模块的字形像素确实是
`#2e3436`，加进列表后才变成 `#abb2bf`。

OBEX / blueman / bluetuith 那一侧见 `bluetooth.md`。

## cffi/niri-windows

模块来自我们自己的 fork（`jwu/waybar-niri-windows`，基线是上游 `v2.3.1` = `17828f9`），
不是上游 release。上游的 x86_64 预编译包会把补丁覆盖掉，所以 `install.sh` 固定到某个
commit 从源码构建，并把该 commit 写进 `~/.config/waybar/waybar-niri-windows.so.version`，
作为「是否已安装」的判据（不像上游那样比 sha256：不同 Go / gtk3 版本编不出同一个字节）。
补丁 push 到 fork 之后，要同步更新 `install.sh` 里的 `WNMW_COMMIT`。

fork 上目前比上游多的两个修复：

- 只有标题变化的 `WindowOpenedOrChanged` 不再触发整块重建。原本终端或浏览器每 80ms 改一次
  窗口标题就会让模块销毁重建光标下的 tile，丢掉 GTK 的 `:hover` prelight —— 看起来就是
  鼠标悬停时小地图在闪。
- PR #20（尚未被上游合并）：`State.Update()` 不再持着 state 锁调用回调。原来它和模块
  `Deinit()` 的锁序相反，waybar 会永久冻结。

当前工作区的窗口小地图。它自己往 waybar 的 GTK 容器里塞 widget，不走 `format` 字符串，
所以上面那套撑高技巧对它不适用。

实测结论（都是量像素 + 强制 SIGUSR2 重建验过的，改之前请重新验证）：

- 命中它的选择器是 `.cffi-niri-windows`。这个类由模块自己添加，它还顺手覆盖了 widget
  name，所以 `#cffi-niri-windows` 根本不存在。
- `margin` / `padding` 对它的布局无效：它是 `GtkEventBox`（继承 `GtkBin`），GTK3 的
  `GtkBin` 分配子节点时只认 `border-width`。
- 不要加纵向 padding/margin：它是拿「自己被分到的高度」去推算窗口像素尺寸的（只在首帧读
  一次），改了会反馈出怪值。
- 上下各留 1px：用 1px 透明上下边框 + `background-clip: padding-box`。同时要把
  `options.column-borders` / `floating-borders` 设成 `2`——模块会从可用高度里扣掉
  `ColumnBorders`，不设就会撑破栏高。
- 颜色：列淡底（前景色 10%）、浮动紫底（15%）、tile 前景色 38% / hover 65%，
  `:active` 是聚焦窗口（蓝），`.urgent` 红。

## module_path 占位符

Waybar 直接 `dlopen()` `module_path`，不展开 `~` / `$HOME`，所以 `config.sh` 在拷贝
`modules.json` 前会把 `__WAYBAR_MODULE_DIR__` 替换成绝对路径（和 swaylock 背景路径同一套
做法）。

## 配色

`colors.css` 定义了基础调色板，以及取自 `config.ghostty` 中 Ghostty One Half Dark 的
`ghostty_*` 强调色。
