# GTK4 / libadwaita 微调

`linux/.config/gtk-4.0/gtk.css` 由 GTK4 自动加载，优先级是
`GTK_STYLE_PROVIDER_PRIORITY_USER`(800)，高于 libadwaita 自带的
`PRIORITY_APPLICATION`(600)，所以这里的规则一定生效。

CSD 窗口的圆角有两个来源：GTK 主题
（`window.csd { border-radius: $window_radius $window_radius 0 0 }`，只圆上面两个角），
或 libadwaita（`var(--window-radius)`，默认 12px）。两者都只在窗口平铺/最大化/全屏时清零，
所以 niri 不开 `prefer-no-csd` 时窗口上面两个角是圆的。

这个文件把圆角（以及 `--window-radius` 变量）清零，不动阴影、边框和其它装饰；菜单、弹窗、
tooltip 的圆角不受影响。
