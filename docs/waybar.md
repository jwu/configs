# Waybar

Linux Waybar setup: `linux/.config/waybar/` (`config.jsonc`, `modules.json`,
`style.css`, `colors.css`, and the scripts under `scripts/`).

## Baseline and line height

Waybar (GTK3) vertically centers each module label in its own cell, and a label's
line height is set by its tallest glyph. A module with a 20px badge next to one
with plain 16px text ends up ~1-1.5px off the same baseline.

Fix: every module `format` starts with two zero-width struts (U+200B, takes no
width):

```
<span size='15pt'>\u200b</span>               raises ascent to 18.7px
<span size='15pt' rise='-1536'>\u200b</span>  raises descent to 7.3px
```

Every line box is then 18.7 + 7.3 = 26px with equal ascent, so baselines match.

Badge glyphs (MDI box letters) are shifted down 2px (`rise='-1536'`) so the box
centers on the digits: 15pt box letters sit 15px above and 1px below the
baseline, and -2px makes it 3px / 3px.

`20px = 15pt`: Pango markup `size` only accepts pt/%/keywords, not px. The tray
and privacy modules use pixel `icon-size` instead.

Exception: the CJK month/day in `#clock` has a taller line box and a different
ascent (~0.7px low), pulled back with `#clock { margin-bottom: 1px }` (GTK3
margin only moves about half).

## Workspace buttons

Waybar loads only the user stylesheet (see `src/client.cpp`), so its own default
`#workspaces button { background-color: transparent }` never applies and
Adwaita's button style leaks in. `background: transparent` clears the gradient,
but not the 1px near-white border, so `border: none` is required too.

## Usage and temperature colors

Low -> green, warning -> yellow, critical -> red. Thresholds live in
`modules.json` `states`; `custom/gpu` thresholds are in `scripts/gpu.sh`,
`custom/gpu-temp` and `custom-ssd` in their scripts.

Temperature padding keeps each reading attached to its component
(`CPU 4% 31°C / GPU 11% 40°C`).

## cffi/niri-windows

Window minimap for the current niri workspace. It inserts its own GTK widgets
instead of using a `format` string, so the strut convention above does not apply.

Findings (measured by pixel counting and forced SIGUSR2 rebuilds; re-verify
before changing):

- The selector is `.cffi-niri-windows`. The module adds this class itself and
  overwrites the widget name, so `#cffi-niri-windows` does not exist.
- `margin` / `padding` do not affect its layout: it is a `GtkEventBox` (a
  `GtkBin`), and GTK3 `GtkBin` sizing honors only `border-width`.
- Do not add vertical padding/margin. The module derives its window pixel sizes
  from the allocated height (read only on the first update), so changing it can
  feed back odd values.
- 1px breathing room comes from a 1px transparent top/bottom border plus
  `background-clip: padding-box`. Set `options.column-borders` and
  `floating-borders` to `2` to match: the module subtracts `ColumnBorders` from
  the available height, so an unset value overflows the bar.
- Colors: column = translucent foreground, floating = translucent purple,
  tile = foreground 0.38 / hover 0.65, `:active` = focused window (blue),
  `.urgent` = red.

## Module path placeholder

Waybar `dlopen()`s `module_path` directly and does not expand `~` or `$HOME`, so
`config.sh` substitutes `__WAYBAR_MODULE_DIR__` with an absolute path before
copying `modules.json` (same approach as the swaylock background path).

## Colors

`colors.css` defines the base palette plus `ghostty_*` accents taken from the
Ghostty One Half Dark palette in `config.ghostty`.
