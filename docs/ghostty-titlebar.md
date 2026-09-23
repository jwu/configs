# Ghostty GTK 标题栏

`config.ghostty` 里的 `gtk-custom-css` 加载 `titlebar.css`（几何）和其中一个
`titlebar-colors-*.css`（配色）。改完用 `Ctrl+Shift+,` 重载，CSS 对已开窗口立即生效。

## 几何

`min-height` 只是容器的下限，容器永远不会比内容矮。Adwaita 有三层相关「地板」：

| 元素 | Adwaita | 这里 |
| --- | --- | --- |
| `headerbar`（容器） | 46px | 22px |
| `button`（图标按钮） | 24px，padding 4px 9px | 18px，padding 1px 4px |
| `windowcontrols button > image`（圆点） | 30px | 18px |

16px 图标和按钮内边距都保留，只去掉多余的高度。

调试：`GTK_DEBUG=interactive ghostty`，选中 headerbar 看实际生效的规则。

## 直角

Adwaita 只圆上面两个角（`window.csd`），并只在窗口平铺/最大化时清零；这里直接清零。全局
那份在 `~/.config/gtk-4.0/gtk.css`，`titlebar.css` 里保留一份是为了这份配置能单独使用。

## Undershoot 线

`gtk-toolbar-style = flat` 时，libadwaita 会给 `AdwToolbarView` 加上 `.undershoot-top`
类，于是终端那块 `GtkScrolledWindow` 顶部的 undershoot 被上色成 1px 硬线 + 4px 渐变——
就是标题栏下面那条暗线。

它不是标题栏的边框，所以：

- 新窗口（终端还没滚出过行）看不到它；
- 一旦有 scrollback（`vadjustment > lower`）就出现，滚回最顶端（`Ctrl+Shift+Home`）又
  消失；
- 换成 `raised` 只是把它换成常亮的同款阴影，`scrollbar = never` 也没用。

把 undershoot 选择器上的 `box-shadow` / `background` 置空即可去掉。

## 配色预设

用 `config.ghostty` 的 `gtk-custom-css` 启用其中一个：

| 文件 | 标题栏 | 文字 | 失焦 |
| --- | --- | --- | --- |
| `titlebar-colors-onedark.css`（当前） | `#282c34` | `#abb2bf` | `#24282f` |
| `titlebar-colors-onedark-purple.css` | `#c678dd` | `#282c34` | `#b26cc7` |
| `titlebar-colors-default.css` | `#222226` | `#ffffff` | `#1e1e22` |

- 紫底对比度约 4.75:1；若文字改用终端前景 `#abb2bf` 只有 1.38:1，会发灰难认，所以刻意
  没用它。
- `default.css` 把 Ghostty 原本自动算出的 chrome 配色（2026-09-22 实测）显式保存下来，
  方便随时切回，也能防止 libadwaita / Ghostty 升级后这套颜色变了。
- 在用户样式表里覆盖 libadwaita 的 `--headerbar-*` 变量无效（实测），所以直接写属性，并
  补 `:backdrop` 保留失焦时略暗的层次。
- `window.csd` 底色跟随标题栏，用来消掉标题栏上方约 2px 的窗口底色色差（终端不透明时不
  外露；开 `background-opacity` 后会从缝隙透出来）。
- 不想要最顶上那 1px 描边时，解开 `window.csd { outline: none }`。
- 另有更暗的紫色方案：标题栏 `#5c3a6e` + 文字 `#abb2bf`（4.31:1），只需改一个变量值。

## 更扁的极端档

`titlebar.css` 里注释掉的极端档把标题栏压到 8px，但只能再省约 10px：再往下是 16px 图标、
窗口标题文字、SplitButton 箭头三块地板。图标尺寸不影响高度，所以没动它。
