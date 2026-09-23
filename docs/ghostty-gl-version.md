# Ghostty 与 Intel HD 4000 的 GL 版本问题

本机 GPU 是 Intel HD Graphics 4000（Ivy Bridge / Gen7，PCI `8086:0166`），Mesa 的
crocus 驱动最高只暴露 **OpenGL 4.2**，而 Ghostty 1.3 要求 **OpenGL 4.3**。硬件路径下
渲染表面（surface）初始化会直接失败，现象是「窗口一闪就消失」，日志为：

```text
info(opengl): loaded OpenGL 4.2
warning(opengl): OpenGL version is too old. Ghostty requires OpenGL 4.3
warning(gtk_ghostty_surface): failed to initialize surface err=error.OpenGLOutdated
warning(gtk_ghostty_surface): surface failed to initialize err=error.SurfaceError
```

没有肉眼可见的错误信息，很容易被误认成 niri 的问题。硬件上限可以直接确认：

```bash
env -u LIBGL_ALWAYS_SOFTWARE eglinfo -B | grep -i "core profile version"
# OpenGL core profile version: 4.2 (Core Profile) Mesa 26.2.3-arch1.1
```

## 解法：谎报版本号，而不是退回软件渲染

早先的办法是 `LIBGL_ALWAYS_SOFTWARE=1`，让 Mesa 走 llvmpipe（软渲染上报 OpenGL 4.6）。
能启动，但代价很大：终端里只要有动画（pi 的 spinner、btop 这类 TUI），每一帧都由 CPU
光栅化，会起 4 个 `llvmpipe-*` 线程把 4 核吃满——实测单窗口 231% CPU，整机 loadavg
冲到 6.8。

改成只让 Mesa 向应用谎报版本号，渲染仍走真正的 Intel 硬件：

```sh
env -u LIBGL_ALWAYS_SOFTWARE \
  MESA_GL_VERSION_OVERRIDE=4.3 \
  MESA_GLSL_VERSION_OVERRIDE=430 \
  ghostty
```

三个变量缺一不可：

| 变量 | 为什么 |
| --- | --- |
| `-u LIBGL_ALWAYS_SOFTWARE` | 必须显式清除。该变量会沿进程树继承——从旧 Ghostty 窗口里再开新窗口、或旧 Hyprland 会话留下的 `env =` 都会把它带进来。不清掉的话 override 与 software 同时生效（llvmpipe 报到 4.3），依旧软渲染 |
| `MESA_GL_VERSION_OVERRIDE=4.3` | 让 crocus 上报 GL 4.3，通过 Ghostty 的版本检查 |
| `MESA_GLSL_VERSION_OVERRIDE=430` | 必需，缺了会 segfault（实测退出码 139，core dumped）。`GL_VERSION_OVERRIDE` 只提 GL 版本、不提 GLSL 版本，Ghostty 要 4.30 的 shader 而驱动只给 4.20 |

效果（同一 `btop` 负载，各采样同一窗口 6 秒）：

| 方案 | 渲染线程 | CPU |
| --- | --- | --- |
| 软件渲染 | 4 个 `llvmpipe-*` | 11.5% |
| 硬件渲染 | 无 | 0.2% |

安全性依据：硬件确实只到 4.2，但 Ghostty 没有依赖 4.3 独有的特性（不需要 compute
shader / SSBO），所以谎报版本不会踩到真实的功能缺失。连续 3 次启动实测均正常退出
（rc=0）。哪天上游开始用 4.3 特性，这里会再次崩溃——那时回退到软渲染。

## 三个注入点

Ghostty 有三条不同的启动路径，彼此绕不过，要分别处理：

1. `~/.local/bin/ghostty` —— PATH wrapper。该目录排在 `/usr/bin` 之前，所以 niri 的
   `Mod+Return`（`spawn "ghostty"`）和 shell 里敲 `ghostty` 都会命中它。
2. `~/.local/share/applications/com.mitchellh.ghostty.desktop` —— 系统桌面项用的是绝对
   路径 `/usr/bin/ghostty`，绕过 wrapper，需要在 `Exec=` 前补 `env`。
3. `~/.config/systemd/user/app-com.mitchellh.ghostty.service.d/gl-version-override.conf`
   —— 桌面项带 `DBusActivatable=true`，fuzzel 之类走 D-Bus 激活，这条路连 `Exec=` 都不
   经过，只能靠 drop-in 的 `UnsetEnvironment=` + `Environment=`。

这三处都是**本机专用、不入库**的文件：它们依赖 Intel HD 4000 这一具体硬件，`config.sh`
也不会覆盖它们（该脚本只复制 `linux/.local/bin/` 下已跟踪的三个 niri 脚本）。同理，
`linux/.config/hypr/hyprland.lua` 里没有也不需要这条 override。

## 验证

```bash
# 1. 版本检查通过
ghostty --gtk-single-instance=false -e sleep 5 2>&1 | grep -i opengl
# info(opengl): loaded OpenGL 4.3

# 2. 没有软件渲染线程
ps -eLo comm= | grep -c llvmpipe
# 0

# 3. 环境变量确实注入了
tr '\0' '\n' < /proc/$(pgrep -n ghostty)/environ | grep -E "MESA|LIBGL"
# MESA_GL_VERSION_OVERRIDE=4.3
# MESA_GLSL_VERSION_OVERRIDE=430
```

环境变量在进程启动时固化：改完 wrapper **必须重开终端窗口**，已在运行的窗口不受影响
（可以用第 2 条命令确认，旧窗口会持续显示 4 个 `llvmpipe-*` 线程）。

## 回退

想退回软件渲染，把 wrapper 的 `exec` 行改回：

```sh
exec env LIBGL_ALWAYS_SOFTWARE=1 /usr/bin/ghostty "$@"
```

代价见上文（TUI 有动画时 CPU 吃满）。若在别的机器上复现同一问题，先确认该机 GPU 的
GL 上限（第一条命令）；只有确实卡在 4.2 且应用非要 4.3 时才用这个 override。
