# Fcitx5 / Rime 托盘图标

waybar 的 `tray` 模块显示的图标**不是 waybar 决定的**：每个 app 通过 D-Bus 的 StatusNotifierItem（SNI）
自己报 `IconName`，waybar 把名字交给 GTK 图标查找，再把查到的位图贴到栏上。所以想换图标只能靠**同名覆盖**，
`tray` 模块本身只能调 `icon-size` / `spacing` / `reverse-direction` / `show-passive-items`（见 waybar.md）。

## 覆盖规则

GTK 的图标搜索路径第一位是 `$XDG_DATA_HOME/icons`（即 `~/.local/share/icons`）：

```
/home/jwu/.local/share/icons     ← 用户目录优先
/home/jwu/.icons
/usr/local/share/icons
/usr/share/icons
```

但**不是"用户目录里任何同名文件都会赢"**。GTK 先比尺寸差距（scalable 视为 0 差距），平手才看目录顺序，
所以在 `tray` 的 `icon-size: 20` 下实测：

| 放法 | 请求 20px 的结果 |
| --- | --- |
| `~/.local/share/icons/hicolor/scalable/apps/fcitx-rime.svg`（自定义 SVG） | ✅ 用户文件胜出 |
| `~/.local/share/icons/hicolor/48x48/apps/fcitx-rime.png`（位图放固定尺寸目录） | ❌ 48 与 20 差 28，系统的 scalable 差 0，仍用系统的 |

结论：**只放 SVG，路径固定 `hicolor/scalable/apps/`**。非要位图就把它包进 `<image>` 的 SVG，或放到与
`icon-size` 完全相同的尺寸目录里。

图标属于哪个主题，就得覆盖那个主题：fcitx5 的图标在 `hicolor`（Adwaita 的 `Inherits=AdwaitaLegacy,hicolor`
把查找链指过去），而 `input-keyboard-symbolic` 属于 Adwaita，要覆盖它必须放
`~/.local/share/icons/Adwaita/symbolic/devices/` —— 放到 hicolor 里不会生效。

### 坑：根元素前面不要留长注释

gdk-pixbuf 的 SVG 探测器只看文件开头几百字节里有没有 `<svg`。如果 `<svg` 之前挂着一条长注释（比如把设计
说明写在文件头），GTK 就认不出这是 SVG，托盘上显示的是一个**缺图占位符**（白纸 + 灰块），而不是你的图标：

```xml
<!-- 错：注释在根元素之前，<svg 被推得太远 -->
<?xml version="1.0" encoding="UTF-8"?>
<!-- 说明……（长） -->
<svg ...>

<!-- 对：说明放在 <svg> 里面 -->
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
  <!-- 说明写在这里 -->
</svg>
```

改完用 waybar 的同一条 gdk-pixbuf 载入路径验证（能出 PNG 才算合格）：

```bash
cat > /tmp/pixload.c <<'C'
#include <gtk/gtk.h>
int main(int argc, char **argv) { gtk_init(&argc, &argv); GError *e = NULL;
  GdkPixbuf *pb = gdk_pixbuf_new_from_file_at_scale(argv[1], 20, 20, TRUE, &e);
  if (!pb) { fprintf(stderr, "%s\n", e->message); return 1; }
  gdk_pixbuf_save(pb, "/tmp/pixload-out.png", "png", &e, NULL); return 0; }
C
gcc /tmp/pixload.c -o /tmp/pixload $(pkg-config --cflags --libs gtk+-3.0)
/tmp/pixload ~/.local/share/icons/hicolor/scalable/apps/fcitx-rime.svg
```

`rsvg-convert` 不会报这个错（它能读整个文件），所以**不能用 `rsvg-convert` 的结果代替这步验证**——踩过。

## 图标名与状态的对应

fcitx5-rime 按状态换 `IconName`，切换后 SNI 属性即时更新（实测：切到键盘布局时立刻变成
`input-keyboard-symbolic`，切回 Rime 立刻变回 `fcitx-rime`）：

| 状态 | IconName | 文件 |
| --- | --- | --- |
| Rime，中文 | `fcitx-rime` | `fcitx-rime.svg`（本仓库覆盖） |
| Rime，英文/Latin 模式 | `fcitx_rime_latin` / `fcitx_rime_latin_upper` | `fcitx_rime_latin{,_upper}.svg`（两张都是 `Aa`，见下） |
| 键盘布局输入法（`keyboard-us`） | `input-keyboard-symbolic` | `Adwaita/symbolic/devices/input-keyboard-symbolic.svg`（本仓库覆盖为 `EN`） |
| 部署 / 同步中 | `fcitx_rime_deploy` / `fcitx_rime_sync` | 系统图标，未覆盖 |
| 托盘菜单里方案子菜单的父项 | `fcitx_rime_im` | 系统图标，未覆盖 |

本仓库覆盖前两行的那四张图；其余状态出现的瞬间很短（部署、同步）或只在菜单里（`fcitx_rime_im`）。

### 键盘布局那张为什么必须放在 Adwaita 目录

fcitx5 没有“每个布局一张图标”的机制：notification-item addon 直接写死 `input-keyboard`，并在**非 KDE** 桌面
把它换成 `input-keyboard-symbolic`（upstream: `src/modules/notificationitem/notificationitem.cpp`，
`keyboardIconName()` 看 `isKDE()`）。这个名字命中 Adwaita 自带的图标，而当前图标主题就是 Adwaita，它的目录比
hicolor 的兜底目录先搜，所以：

| 放法 | `input-keyboard-symbolic` 的解析结果 |
| --- | --- |
| `~/.local/share/icons/hicolor/scalable/devices/…` | ❌ 仍解析到 `/usr/share/icons/Adwaita/symbolic/devices/…` |
| `~/.local/share/icons/Adwaita/symbolic/devices/…`（同原文件的相对路径） | ✅ 用户文件胜出 |

另外 symbolic 图标会被 GTK 重新上色成当前控件颜色（waybar 里就是 `#tray { color: @ghostty_fg }`），所以文件里
写什么 `fill` 都只算兜底，真正决定颜色的是 waybar 的 CSS。

### 上游限制：大小写（`_upper`）在 Wayland 下不会出现

fcitx5-rime 挑图标的条件（upstream: `src/rimeengine.cpp`）：

```cpp
if (status.is_disabled)      icon = "fcitx_rime_disable";
else if (status.is_ascii_mode) {
    icon = "fcitx_rime_latin";
    if (isCapsLockOn(&ic))   icon = "fcitx_rime_latin_upper";
}
else                         icon = "fcitx-rime";

bool RimeEngine::isCapsLockOn(InputContext *ic) const {
    if (auto xkbState = instance_->xkbStateMask(ic->display())) {   // ← Wayland 下为空
        return std::get<2>(*xkbState) & uint32_t(KeyState::CapsLock);
    }
    return false;
}
```

也就是说它看的是 **CapsLock 锁定状态**（不是“你正在打大写”、也不是 Shift），而这个状态要 fcitx5 核心持有对应
显示器的 XKB state 才读得到。本机所有应用都是 `frontend:wayland_v2`（`fcitx5-diagnose` 里可见），走的是
text-input 协议，没有 XKB state → `isCapsLockOn()` 恒为 `false` → **无论 CapsLock 开没开，托盘都显示小写 `a`**。

实测：用 `wtype -k Caps_Lock` 注入 CapsLock 能让 rime 进入 Latin 模式（图标变 `fcitx_rime_latin`），但图标永远
停在 `a`，内核 caps lock LED（`/sys/class/leds/input*::capslock/brightness`）也一直是 0 —— 注入的键不会改
compositor 的锁定状态，所以这条路径只能证明“拿到 `_upper` 不靠键盘事件”，不靠配置能改。要在 Wayland 上靠图标
区分大小写，得等上游换成从 keymap/frontend 拿 caps 状态。

副作用：这种注入的 CapsLock 会把 rime 顶在 Latin 模式（rime 认为 caps 一直按着）。让 rime 回到中文的干净办法是
托盘菜单的 **Synchronize**（upstream `RimeEngine::sync()` → `releaseAllSession()`，新 session 会套用
`switches` 里的 `reset` 值，本仓库 `rime_ice.custom.yaml` 里 `reset: 0` 就是中文），不用重启 fcitx5。

因为这层限制，本仓库把**两张 latin 图标做成同一张 `Aa`**：托盘只表达“英文模式”，不假装能区分大小写。等上游
改成从 keymap/frontend 取 caps 状态后，再把 `fcitx_rime_latin.svg` 与小写/大写分开即可。

## 设计约定

- 四张图都是**纯文字、无底牌**：统一 16×16 viewBox，跟键盘布局那张 `EN` 一个风格。`icon-size: 20` 下
  实际墨迹实测：`中` 12×14px、`Aa` 12×11px、`EN` 12×11px（CJK 字形天生比拉丁大写高，正常）
- 字号：`中` 12.5pt（中文基本满框）、`Aa` / `EN` 11.5pt（两个拉丁字符）
- 颜色 `#abb2bf`（= waybar `@ghostty_fg`）。**注意**：只有键盘布局那张会跟着栏的 CSS 变（它的名字以
  `-symbolic` 结尾，GTK 会重新上色）；Rime 那三张名字是固定的，不会被重上色，所以颜色是写死的，改栏的
  配色时要记得一起改
- 字体 `Sarasa Mono SC`（`linux/install.sh` 装的 `ttf-sarasa-gothic`），后面挂 `Noto Sans CJK SC` 兜底；
  换机器没装这些字体时会退到通用 `sans-serif`，颜色不受影响

## 生效与还原

```bash
# 覆盖后必须重启 waybar：GTK 会缓存图标查找结果和位图，光改文件不会刷新
pkill -x waybar && niri msg action spawn -- waybar

# 还原：删掉用户目录里这四张图即可，系统图标没被动过
rm ~/.local/share/icons/hicolor/scalable/apps/fcitx-rime.svg \
   ~/.local/share/icons/hicolor/scalable/apps/fcitx_rime_latin.svg \
   ~/.local/share/icons/hicolor/scalable/apps/fcitx_rime_latin_upper.svg \
   ~/.local/share/icons/Adwaita/symbolic/devices/input-keyboard-symbolic.svg
```

fcitx5 不需要重启。

诊断（看当前应该显示哪张图）：

```bash
# fcitx5 的 SNI 唯一名（:1.xxx）
busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
  org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems
# 再拿图标名，切换输入法时它会变
busctl --user get-property :1.xxx /StatusNotifierItem org.kde.StatusNotifierItem IconName
```

图标名和 tooltip 文字都不在配置里：它们来自 addon 与 gettext 目录（所以 `LANG=en_US.UTF-8` 时菜单里是
`Rime` / `Latin Mode`，`zh_CN` 时是「中州韵 / 英文模式」）。改文字要自己写 `.mo`，本仓库不做。
