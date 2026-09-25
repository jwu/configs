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

低负载绿、告警黄、危急红。阈值在 `modules.json` 的 `states`；`custom/gpu` 和 `custom/gpu-temp`
的阈值写在 `src/gpu-watch.c` 顶部（util 70/90，temp 75/85），`custom/ssd` 在 `disk-temp.sh` 里。

温度模块的 padding 让读数紧贴所属组件，读起来是一组：`CPU 4% 31°C / GPU 11% 40°C`。

## 磁盘模块（disk-temp.sh）

`custom/ssd` 背后是 `~/.config/waybar/scripts/disk-temp.sh`，取**全机最热的那块盘**。它扫
`/sys/block`，再用 hwmon 的 `device` 符号链接把每块盘对上自己的传感器，所以没有写死的 PCI
地址和盘数：只有 SATA 机械盘的机器显示 `HDD`（󰬏󰬋󰬋），有 NVMe 的显示 `SSD`（󰬚󰬚󰬋），混合机器
按最热那块决定图标。机械还是固态看 `/sys/block/*/queue/rotational`（1 = HDD）。

SATA 盘的读数来自 `drivetemp` 内核模块，它**不会自动加载**，没有它那些盘只显示 `--°C`。
`config.sh` 会 `modprobe` 一次，并写 `/etc/modules-load.d/drivetemp.conf` 让它开机加载。

阈值不是写死的：每块盘用自己的 `temp1_max` / `temp1_crit`（NVMe 来自标准字段 WCTEMP/CCTEMP，
SATA 由 drivetemp 报出，本机 HDD 是 60/65），盘不报或报 0 时回退 60/75。因为阈值逐盘不同，
模块显示的盘是**状态最严重的那块**（critical > warning > 正常，同级取更热），而不是单纯最热的
那块；tooltip 每行带该盘自己的上限：`sda: 37°C  (HDD, max 60 / crit 65)`。和 GPU 一样只输出
`class`，颜色由 `style.css` 决定。

阈值之外的另一个数：`modules.json` 里 `interval: 30`。硬盘热容大，温度是分钟级变化，5 秒采样
纯属过采样——这里省下的是每 5 秒 9 次进程创建的调度器唤醒。脚本本身也全用 bash 内建：
`$(<file)` 读 `/sys`、参数扩展处理型号、`cd` + `pwd -P` 解析符号链接，每次运行 **0 个外部进程**
（带 `cat`/`sed`/`readlink` 时约 19ms，现在约 9ms）。

## GPU 模块（gpu-watch）

两个 GPU 模块背后是 `~/.local/bin/gpu-watch`，由 `linux/src/gpu-watch.c` 编出来（`install.sh`
里一句 `gcc -O2 ... -ldl`）。它用 **dlopen 打开 `libnvidia-ml.so.1`**：不链驱动、不需要
`nvml.h`、没有构建期依赖。驱动不在时它打一行 `class: off` 就退出，`modules.json` 里的
`restart-interval: 10` 会再把它拉起来（驱动重载/休眠回来后也是这么恢复的）。

**为什么不再用 `scripts/gpu.sh`**（已删）：那个脚本每次 spawn 一个 bash + nvidia-smi，实测
16.8 ms CPU / 21.5 ms 墙钟；两个模块每 2 秒各一次，waybar 含子进程的用量是 **4.60% 个核**
（waybar 自己才 ~1.2%）。贵的主要是 nvidia-smi 的启动：`nvmlInit` 一次 9.9 ms，每个样本都
重付一遍；同样的两个设备查询在进程内只要 **0.017 ms**。

实测对比（同一台机器，`utime+stime+cutime+cstime` 算 20 秒）：

| 方案 | 每 2 秒采样 | waybar 含子进程 |
| --- | --- | --- |
| `gpu.sh`（bash + nvidia-smi ×2） | 2 × 16.8 ms | **4.60% 个核** |
| 零代码：常驻 `nvidia-smi -lms 2000` | 5.38 ms（它每个样本仍然要 5.38 ms） | ~2.7% |
| **常驻 `gpu-watch`，两个进程** | 2 × 0.017 ms | **2.15% 个核** |

省下 2.45% 个核，剩下的 2.15% 基本就是 waybar 自己和 cffi 模块的 `/proc` 采样 —— 现在
`ps --ppid $(pgrep -x waybar)` 里只剩这两个常驻进程。启动时每个进程一次性付 ~15 ms
（dlopen + nvmlInit），之后每个样本低于 10 ms 的时钟粒度。

机制：waybar 的 `custom` 模块在**没有 `interval` / `signal`** 时假定脚本自己循环（man page：
*“If no `interval` or `signal` is defined, it is assumed that the out script loops itself.”*），
按行读 stdout。所以这两个模块里没有 `interval`，只有 `restart-interval`；`gpu-watch` 每次
采样后 `fflush`，否则管道缓冲会让 waybar 一直看不到新行。（调试用 `gpu-watch util -once`
打一行就退出。）

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

`nm-applet` 的托盘图标与这个模块重复，所以它的 XDG autostart 被
`~/.config/autostart/nm-applet.desktop`（`Hidden=true`）覆盖关闭；系统文件
`/etc/xdg/autostart/nm-applet.desktop` 不动，`config.sh` 负责部署这份覆盖。

## cffi/niri-windows

模块来自我们自己的 fork（`jwu/waybar-niri-windows`，基线是上游 `v2.3.1` = `17828f9`），
不是上游 release。上游的 x86_64 预编译包会把补丁覆盖掉，所以总是从源码构建，并把构建的
commit 写进 `~/.config/waybar/waybar-niri-windows.so.version`，作为「装的是哪一版」的判据
（不像上游那样比 sha256：不同 Go / gtk3 版本编不出同一个字节）。

目标版本是 **fork main 的 HEAD**，由 `linux/waybar-niri-windows.sh` 里的 `wnmw_want_commit`
解析（`git ls-remote`），所以把补丁 push 到 fork 之后不需要改任何 pin：

- `install.sh`（新机器）构建 HEAD 并写下 `.version`；
- `config.sh`（已有机器）拿 `.version` 和 HEAD 比对，不一致就从源码重建 —— 这就是
  「更新了 dotfiles 但模块还是旧的」不再发生的原因。2026-09-23 就是这么漏掉的：当时只跑了
  `config.sh`，而它的旧版只检查 `.so` **是否存在**，文件在就永远不提示。

`WNMW_COMMIT=<sha> ./install.sh` 可以显式覆盖（复现旧版本）。GitHub 不可达时 15 秒超时后
回退到脚本里的 `WNMW_FALLBACK_COMMIT`（当前 `3f30472`，即切 focus 不再重建、活动色建砖时
就上的那版）；此时 `.version` 若已等于 fallback 就直接跳过，离线不会误重建（fork 未推送时
记得同步 bump 这个常量）。

本机直连 GitHub 常常不通（mihomo 在 7890，见 `.zshrc` 里的 `proxy` 别名），要让重建走代理就
带上环境变量，或让 `WNMW_REPO` 走 SSH：

```bash
https_proxy=http://127.0.0.1:7890 bash linux/config.sh
WNMW_REPO=git@github.com:jwu/waybar-niri-windows.git bash linux/config.sh
```

### 别就地覆盖 `.so`

waybar `dlopen()` 之后一直把 `.so` 映射着，**就地覆盖这个文件（`cp` / `install` 到同一个
路径）会在 1~2 秒内把它打死**：`SIGSEGV` 或 `SIGILL (ILL_ILLOPN)`，同时留一个 core。
2026-09-23 晚上当场复现过（覆盖后 2 秒死），当晚 6 个 waybar core 都是这么来的；
09-23 15:02 / 15:03 那两个也正好对上写备份的那几次构建（09-21、09-22 各一个，大概率同理，
没有旁的证据）。

做法：先装到 `.new` 再 `mv -f` 顶上去（rename 换 inode，老映射继续有效）。
`install.sh` / `config.sh`（共用 `linux/waybar-niri-windows.sh`）和 fork 里的
`build-and-install.sh` 都这么做；重启 waybar 仍然必要，但不再需要「先关 bar 再装」。

2026-09-24 之前，活动状态那套（`procs/` + `module/activity.go`）只活在 fork 的
`busy-state` 分支上，而这里构建追的是 **main HEAD**，于是 CSS 里的
`.tile.light` / `.medium` / `.heavy` 从不命中，小窗一直只有灰 / 蓝 / 红。已把
`busy-state` 合入 main（merge commit `c6dfc27`），main 重新成为唯一真源 —— 功能开发完就并回
main，别让它长期只待在 side branch 上（那次唯一的冲突是两边各自实现的 rename 安装，取任一份即可）。

fork 上目前比上游多的四个修复：

- 只有标题变化的 `WindowOpenedOrChanged` 不再触发整块重建。原本终端或浏览器每 80ms 改一次
  窗口标题就会让模块销毁重建光标下的 tile，丢掉 GTK 的 `:hover` prelight —— 看起来就是
  鼠标悬停时小地图在闪。
- 切 focus 不再触发整块重建。原来 `WindowFocusChanged` 也会把整个小地图推倒重建，而重建
  之后每一块**带活动色的**砖都要把类重新加一遍，那是一次样式变化，CSS 的 75ms `transition`
  于是把每块砖从灰色淡回本色 —— 看着就是「每次切窗口小地图闪一下」。现在 `niri.State` 分开
  记 `layoutVersion` / `focusVersion`，只有布局变了才重建，focus 只改 `:active`；活动色也
  改成建砖时（`add` 之前）就上。细节和实测数字见下面「重建与闪烁」。
- PR #20（尚未被上游合并）：`State.Update()` 不再持着 state 锁调用回调。原来它和模块
  `Deinit()` 的锁序相反，waybar 会永久冻结。
- 窗口活跃度按窗口测：shell 把自己的 pid 写进窗口标题（不可见 tag 字符），单实例终端的几个
  窗口不再一起亮。见下面「每窗口独立测量：shell 在标题里自报 pid」。

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

### 重建与闪烁

`niri.State` 记两个计数器：`layoutVersion` 只在「砖本身要重排」的事件上 +1（开/关窗口、
布局变化、切换工作区、urgent……），`focusVersion` 在这些事件上一起 +1，另外在「只是聚焦变
了」的事件上单独 +1（`WindowFocusChanged`，以及 `WindowOpenedOrChanged` 里那个「新聚焦」
分支）。模块记住上次画完时的那一对，只有 layout 变了才重建；只动 focus 时走一遍
`markFocusedTiles()`，改砖（连同列、浮动层）的 `:active`。哪个事件算哪一类钉在
`niri/niri_state_test.go` 里。

两条用 wlr-screencopy 抓帧量出来的结论（约 600 fps 抓栏上 `2100..2400 × 0..34`，看砖心
像素；一次抓 `1200` 帧左右就够覆盖一次切换）：

- **重建本身不闪**：`Update()` 在一个 GTK 回调里把所有砖 `Destroy()` 再重建，重建后那一帧
  砖就在、尺寸也对，中间不漏空帧。会闪的是下一条。
- **activity 类必须赶在 `add` 之前加**：GTK3 在 widget realize 时算样式，而**把 widget add
  进已经 realize 的容器就等于 realize 它**（`gtk_widget_get_realized()` 立刻为真，哪怕
  `visible` 还是 0）。所以「先 `ShowAll()` 再 `applyActivityLocked()`」是错的：那成了样式
  变化，75ms 过渡把砖从灰淡到本色。同一块 medium 砖的像素：重建帧 `(98,102,113)`，69ms 后
  `(229,192,123)`，中段是过渡色。改成建砖时在 `colBox.Add()` / `floatingFixed.Put()` 之前
  调 `colorTile()` 之后，重建帧就是本色，之后不动。

前后对比（同一份抓帧）：修之前每次切 focus，所有带活动色的砖一起「灰一下再淡回来」；修之后
只有真正换了聚焦的**两块**砖在 75ms 里交叉淡入淡出（一块蓝→本色、一块本色→蓝），其余砖逐个
像素不变 —— 那个交叉淡入本来就是 `transition` 的本意，不算闪。

`i.box.ShowAll()` 只在 `Update()` 末尾调一次；`drawFloating()` 里那次 `ShowAll()` 是多余的
（末尾那次会递归到），但留着无害，没动。

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
  一个终端里在跑任务，5 块砖一起黄；一个 Chrome 的全部窗口同理。**终端这类已经修掉**（见
  下面「每窗口独立测量」）：窗口的 shell 宣告过就按它自己的子树算；Chrome、
  `ghostty -e <TUI>`、没有 shell 片段的 bash 仍然是进程粒度。
- **CPU 不动就算闲着**：`sleep 100`、纯等网络、GPU 硬解视频都是 0；反过来，一个纯粹在搬
  文件的窗口（`cp` 大文件、同步）大部分时间在等 I/O，CPU 不高，所以看起来只是「一点点忙」。
- **Xwayland 会串味**：它是某些 X11 客户端的子进程，别的 X11 应用一忙，那棵子树也跟着涨。
- 第二个 bar 会再起一份采样器（tracker 属于实例），开销翻倍。

### 每窗口独立测量：shell 在标题里自报 pid

上面那条「pid 是进程粒度」的漏报，对单实例终端最扎眼（ghostty 默认单实例，5 个窗口共用
pid 1939）：一个终端里编译，5 块砖一起黄。修法是让 **shell 自己报身份**。

niri 每个窗口只给一个 pid，能按窗口区分的只有 `title`（客户端随便设，niri 原样透传）。而
shell 知道自己在哪个窗口里 —— 终端显示的标题就是这个窗口的标题 —— 所以让 shell 把自己的
pid 写进标题，模块从标题里读出来，就得到「窗口 ↔ 这棵子树」的精确对应，不需要猜。

协议在 `module/marker.go`：标题末尾追加 `U+E0001` + 十进制 pid 的 TAG DIGIT + `U+E007F`。
全是 Unicode 的 format 字符（default-ignorable），没有任何渲染器会画出来；实测用
`pango-view` 分别渲染带标记和不带标记的标题，两张 PNG 逐字节相同。模块只认完整形态
（开 + 至少一位数字 + 闭），所以 emoji 的 tag 序列（旗帜末尾也是 `U+E007F`）不会被误读。

shell 侧是 `linux/.config/waybar/zsh-announce.zsh`（`config.sh` 拷到
`~/.config/waybar/zsh-announce.zsh`，`linux/.zshrc` 末尾 source 它），只做一件事：注册一个
`precmd` hook，在每个提示符前把标题重写成「prompt 自己会写的那个 idle 标题」+ 标记 ——
文本取自 `ZSH_THEME_TERM_TITLE_IDLE`（oh-my-zsh 和多数主题都会设它），没有这个变量则退回
ghostty 那套截断工作目录。实测和 oh-my-zsh 自己写的那串剥掉标记后**逐字节相同**，所以窗口
名字不变。几条刻意的取舍：

- 只在 `precmd` 写，不碰命令行标题（`preexec`）；命令运行期间标题里没有标记，模块用上一次
  提示符学到的 pid。
- 如果以后有别的插件也写标题、且注册得比我们晚，它会盖掉我们：那个窗口退化成下面的回退
  行为，标题本身不受影响。
- 写之前剥掉控制字符，目录名里带控制字符时不会打断 OSC 序列。

模块侧取 pid 的优先级（`module/announcement.go`）：

| 情况 | 测什么 |
| --- | --- |
| 标题里有合法标记，且该 pid 仍是**这个窗口 pid 的后代** | 那个 pid 的整棵子树（通常是这个窗口的 shell） |
| 标题没有标记，但记得它上次宣告过的 pid（同样过校验） | 同上 |
| 从来没宣告过 / 标记不可信 | 退回这个窗口的 pid（应用整棵树）；**但如果同一应用里已经有窗口宣告过**，这一格干脆不给色 —— 那棵树里混着兄弟窗口的负载，报出来就是假的亮 |

「后代校验」每次采样都做（沿父链读几个 `/proc/<pid>/stat`），挡的是 pid 回收、以及某个程序
把别的窗口的标记抄进自己标题的情况。

**缓存**：`~/.cache/waybar-niri-windows/announced.json`，内容是「窗口 id → 应用 pid + 宣告的
pid」。存在的理由有两个：TUI（pi / vim）会占住标题、把标记盖掉；bar 重启时内存里的映射会
丢。两个 pi 窗口即使在 pi 跑着、甚至 bar 重启之后仍然各自独立，靠的就是它。条目在使用前都
用 `/proc` 校验（应用 pid 要对得上、宣告的 pid 要是它的后代），下次写文件时清掉进程已经不
在的条目；只在真有 shell 宣告过之后才会创建这个文件。

已知边界（都不会误报，最多是「这一格没颜色」）：

- `ghostty -e <TUI>` 没有交互 shell，从来不会宣告；`bash` 没有等价片段（目前只有 zsh 版）。
- 非交互 shell（`zsh -c`、脚本）不读 `.zshrc`，自然不宣告。
- 窗口被手动设过标题（ghostty 命令面板 *Change Terminal Title…*）时是 title override，会压过
  所有 OSC 标题写入 —— 那个窗口没有标记，走回退；你的手动标题也不会被改掉。
- 标题字符串里确实带着不可见字符：做**精确匹配**的东西会看到它。niri 自己的 `title=` 窗口
  规则是非锚定正则（`niri-config` 的 `RegexEq` 就是 `Regex`），不受影响；显式写 `^...$`
  才需要留意。模块自己的 window rule 和 tooltip 用的是剥掉标记的标题。
- `hidepid=2` 或 root shell 会让后代校验失败 → 优雅退回应用树。

调试：`-tags debug` 的构建会打 `window N is measured by announced pid M`（以及「同应用已有
宣告所以不给色」）；`-tags trace` 每次采样打一行「窗口 → pid」。跨语言那一跳（zsh 写出的字节
和 Go 解析的语法是否一致）由 `module/marker_test.go` 真跑一次 zsh 校验，脚本按
`$WNW_ANNOUNCE` → `~/.config/waybar/zsh-announce.zsh` → `../contrib/`（旧 checkout）查找，
都不在就 skip。

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
