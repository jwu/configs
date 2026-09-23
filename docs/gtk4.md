# GTK4 / libadwaita tweaks

`linux/.config/gtk-4.0/gtk.css` is loaded automatically by GTK4 at
`GTK_STYLE_PROVIDER_PRIORITY_USER` (800), above libadwaita's
`PRIORITY_APPLICATION` (600), so its rules win.

CSD windows get rounded corners from either the GTK theme
(`window.csd { border-radius: $window_radius $window_radius 0 0 }`, top corners
only) or libadwaita (`var(--window-radius)`, 12px by default). Both clear the
radius only when the window is tiled/maximized/fullscreen, so a niri window
without `prefer-no-csd` shows rounded top corners.

The file zeroes the radius (and the `--window-radius` variable) without touching
shadows, borders or other decorations. Menus, popups and tooltips are unaffected.
