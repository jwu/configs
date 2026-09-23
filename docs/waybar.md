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
| `connected` | 至少 1 个设备已连接 | 󰂱 | `@ghostty_blue` |
| `off` | 适配器 `Powered=false` | 󰂲 | `@ghostty_red` |
| `disabled` | 被 rfkill 屏蔽 | 󰂲 | `@ghostty_red` |
| `no-controller` | 系统没有适配器 | 󰂲 | 默认前景色 |

`format-icons` 写成对象时按 state 取，取不到才回退 `default`（`ALabel::getIcon`），所以每个
state 都显式写了键。

`#bluetooth` 必须待在 `color: @ghostty_fg` 那个选择器列表里。漏掉的话它会用 GTK 默认前景色
`#2e3436`，叠在 `@ghostty_bg`（`#282c34`）上肉眼等于隐形——实测该模块的字形像素确实是
`#2e3436`，加进列表后才变成 `#abb2bf`。

OBEX / blueman / bluetuith 那一侧见 `bluetooth.md`。

## network

状态同样是模块自己加的 CSS 类（`update_style_context`），配色是「有线蓝、无线绿、屏蔽红」：

| state | 触发条件 | 颜色 |
| --- | --- | --- |
| `ethernet` | 活动接口是有线且已连上 | `@ghostty_blue` |
| `wifi` | 活动接口是无线且已连上 | `@ghostty_green` |
| `disabled` | 接口被 rfkill 屏蔽 / 没有可用接口 | `@ghostty_red` |
| `disconnected` | 有接口但链路没起来 | 无规则，回退到色彩列表里的 `@ghostty_fg` |

有线拿蓝色，所以蓝牙 `connected` 也留在蓝色上，两者只靠图标区分（`󰈀` / `󰂱`）。

## cffi/niri-windows

模块来自我们自己的 fork（`jwu/waybar-niri-windows`，基线是上游 `v2.3.1` = `17828f9`），
不是上游 release。上游的 x86_64 预编译包会把补丁覆盖掉，所以 `install.sh` 固定到某个
commit 从源码构建，并把该 commit 写进 `~/.config/waybar/waybar-niri-windows.so.version`，
作为「是否已安装」的判据（不像上游那样比 sha256：不同 Go / gtk3 版本编不出同一个字节）。
补丁 push 到 fork 之后，要同步更新 `install.sh` 里的 `WNMW_COMMIT`。

### 别就地覆盖 `.so`

waybar `dlopen()` 之后一直把 `.so` 映射着，**就地覆盖这个文件（`cp` / `install` 到同一个
路径）会在 1~2 秒内把它打死**：`SIGSEGV` 或 `SIGILL (ILL_ILLOPN)`，同时留一个 core。
2026-09-23 晚上当场复现过（覆盖后 2 秒死），当晚 6 个 waybar core 都是这么来的；
09-23 15:02 / 15:03 那两个也正好对上写备份的那几次构建（09-21、09-22 各一个，大概率同理，
没有旁的证据）。

做法：先装到 `$out.new` 再 `mv -f` 顶上去（rename 换 inode，老映射继续有效），
`build-and-install.sh` 已经这么改了。重启 waybar 仍然必要，但不再需要「先关 bar 再装」。
`install.sh` 里那句 `cp ... "$WNMW_DEST"` 还是就地覆盖。

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

### 窗口活动状态（灰 / 绿 / 黄 / 红）

tile 底色表示「这个窗口在干活，干得有多猛」，四档，外加一个正交的聚焦：

| 类名 | 含义 | 颜色 | 触发区间（整棵进程树的 CPU） |
| --- | --- | --- | --- |
| （无） | 闲着 | 前景色 38%，实测 `(98,102,113)` | < 8% 个核 |
| `light` | 一点点忙 | `@ghostty_green` `(152,195,121)` | 8% ~ 20% 个核 |
| `medium` | 较忙 | `@ghostty_yellow` `(229,192,123)` | 20% ~ 1.5 个核 |
| `heavy` | 很忙 | `@ghostty_red` `(232,102,113)` | ≥ 1.5 个核 |
| （聚焦） | 你在看它 | `@ghostty_blue` `(97,175,239)` | 与活动无关，压过上面四档 |

三个边界都故意取在小数上（1.5 个核，而不是 1 或 2），因为真实负载就停在整数核上：单线程
任务正好是 1.0 个核，边界放在那里会红黄来回闪。踩过：边界设 0.9 时，97% 核的终端确实在
红黄之间跳，截屏抓到的是过渡中的 `(229,102,113)`，而不是纯红 `(232,102,113)`。

灰的界线（8% 个核）也是踩出来的，而且是先从 3% 提上来的：原来定在 1.2%，结果一个什么都
不干的后台标签页、加上开了几个终端，整条小地图绿成一片；提到 3% 后 Chrome 还是常绿，因为
它的背景负载正好压在 3% 上下（实测 30 秒里 20 秒被点亮），换成中位数之后才彻底不亮。

信号**只有 CPU**，来自 `/proc` 而不是 niri：niri 只说得出窗口的 `pid`，模块拿这个 pid 把
整棵进程树（含 zsh 里的编译器、Chrome 的 renderer 进程）每秒采样一次 `utime+stime`，换算成
「用了多少个核」。GPU 和块 I/O 都不看，理由见下面单独一节。

**档位取的是最近 5 个样本的中位数，不是瞬时值。**这是为了治「闲着也常绿」：实测一个闲置
的 Chrome（后台在跑定时器/轮询的页面）整棵树在 1~6% 核之间稳步爬，还会**偶发冲到 30%**，
用「瞬时值 + 衰减」的话那些尖峰会直接把砖点亮。中位数要 5 个里有 3 个超阈值才动，1 秒的
尖峰动不了。

代价（都是有意选的）：

- 普通负载要**持续 3 秒**才显示；但超过 `heavy` 阈值（1.5 个核）的负载**第一秒就红**，
  大活不需要滤波。
- 收工后也是 3 秒回落，而且是**一步回灰**，不再有黄/绿的过渡。
- 每秒高低交替的负载可能被中位数完全滤掉（5 个里凑不出 3 个高的），目前没遇到，先记下。

各档的具体行为钉在 `procs/procs_test.go` 里（包括两个 30% 尖峰不能点亮一块砖的回归测试），
常数在 `procs/procs.go` 顶部。

不用「标题最近变过」：`State.Update` 故意丢弃 title-only 事件（就是上面那个修复），靠它
等于把 hover 闪烁放回来。

CSS 顺序有讲究：`.tile.light` / `.tile.medium` / `.tile.heavy` 必须写在 `.tile:hover`
之后、`.tile:active` 之前。GTK3 同特异性取后一条，于是 `hover < 三档活动 < 聚焦 < urgent`
——聚焦的窗口永远是蓝的，即使它正忙（量过像素：`97,175,239` 正是 `@ghostty_blue`）。三档
之间互斥，彼此顺序无所谓；`.tile.urgent` 排在最后，所以它压过 `heavy` 的红。

开销（20 线程机器，45 秒窗口、两种 .so 交错各测 3 次）：

| | waybar 自身 |
| --- | --- |
| 不带采样器 | 1.24% 核 |
| 带采样器（1 Hz） | 1.82% 核 |
| 差 | **+0.58% 核** |

大头是采样本身：一次 `Update` 中位 **3.2 ms**、p90 5.9 ms、最差 12 ms（30 次实测），
几乎全花在给 400 个进程各开一次 `/proc/<pid>/stat`（12.9 µs/进程），而真正关心的只有窗口
那 20~30 个进程。省不掉——拿 ppid 必须扫全表，改用 `/proc/<pid>/task/<tid>/children` 从
窗口根往下走并不更快（Chrome 一个进程上百个线程）。等级没变时模块不碰 GTK（不遍历、不发
idle），稳态下代价就是那次扫描。

已知漏报 / 误报（都接受，别当 bug 修）：

- **pid 是进程粒度**：同一进程的多个窗口一起亮。实测 5 个 ghostty 窗口共用 pid 1939，
  一个终端里在跑任务，5 块砖一起黄；一个 Chrome 的全部窗口同理。
- **CPU 不动就算闲着**：`sleep 100`、纯等网络、GPU 硬解视频都是 0；反过来，一个纯粹在搬
  文件的窗口（`cp` 大文件、同步）大部分时间在等 I/O，CPU 不高，所以看起来只是「一点点忙」。
- **Xwayland 会串味**：它是某些 X11 客户端的子进程，别的 X11 应用一忙，那棵子树也跟着涨。
- 第二个 bar 会再起一份采样器（tracker 属于实例），开销翻倍。

### 为什么 GPU 和块 I/O 都不看

当初想要的是「cpu + gpu + io」三个信号，最后只留了 CPU。

块 I/O 的理由很简单：真正以磁盘为主、CPU 几乎不动的窗口很少，而它要额外为每个树成员读
一个 `/proc/<pid>/io`。`rchar/wchar` 更不能用——那算的是 syscall 流量，pty 流量也是
syscall 流量，一个只是在刷 spinner 的闲置终端会有稳定几十 KB/s，而实测 waybar 自己是全场
最大的读者（115 KB/s）。

GPU 则是「能拿到，但不值得」。结论记在这里，哪天要接就从这里开始：

- nvidia 专有驱动**不给** `/proc/<pid>/fdinfo` 里的 `drm-engine-*`（那是 amdgpu/i915 的
  做法），这台机器上实测 0 个 fdinfo 带引擎统计。
- 但 `nvidia-smi pmon` 的 sm/mem/enc/dec 列在这里是**真的 per-process**：1474 niri 和
  1939 ghostty 各自变动且和 ≈ 全局 utilization；起一个 nvenc 任务，`enc=64` 正好落在
  ffmpeg 的**编码子进程**上——所以仍然要按进程树求和。
- 代价差两个数量级：`nvidia-smi pmon -d 1` 常驻流式 18.8 ms/样本（≈1.9% 个核，比整个功能
  还贵三倍），而直接 `dlopen("libnvidia-ml.so.1")` 调
  `nvmlDeviceGetProcessUtilization` 只要 **0.02 ms/次**（≈0.002% 个核）。

所以正确做法是 NVML：布局是 `{u32 pid, u32 vgpu, u64 ts_ns, u32 sm, mem, enc, dec}`（32
字节，系统里没装 `nvml.h`，是从原始字读出来的）；dlopen 失败就整路关掉，非 nvidia 机器上
本来也没有这个文件。两个坑：驱动会往缓冲里填 `pid=0` 的填充行，而且返回的计数**可能超过
你给的容量**（实测传 64 返回 72），所以缓冲要给足、计数要夹紧。

## module_path 占位符

Waybar 直接 `dlopen()` `module_path`，不展开 `~` / `$HOME`，所以 `config.sh` 在拷贝
`modules.json` 前会把 `__WAYBAR_MODULE_DIR__` 替换成绝对路径（和 swaylock 背景路径同一套
做法）。

## 配色

`colors.css` 只有一套调色板：`ghostty_*`，值一一对应 `config.ghostty` 里的
`palette = N=...`（当前主题 One Half Dark），命名就是 ANSI 槽位的语义
（`ghostty_red` = palette 1）。没有第二套颜色，所以终端里的红和状态栏里的红是同一个 hex；
换 ghostty 主题时这里要跟着改。

`ghostty_grey`（palette 8）留给滑条槽道这类「非强调」的灰。
