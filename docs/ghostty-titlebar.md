# Ghostty GTK titlebar

`gtk-custom-css` in `config.ghostty` loads `titlebar.css` (geometry) and one
`titlebar-colors-*.css` (colors). Reload with `Ctrl+Shift+,`; CSS applies to open
windows immediately.

## Geometry

`min-height` is only a floor: a container is never shorter than its content.
Adwaita has three relevant floors:

| Element | Adwaita | Here |
| --- | --- | --- |
| `headerbar` (container) | 46px | 22px |
| `button` (icon buttons) | 24px, padding 4px 9px | 18px, padding 1px 4px |
| `windowcontrols button > image` (dots) | 30px | 18px |

The 16px icons and the button padding are kept, so only the excess height is
removed.

Debug with `GTK_DEBUG=interactive ghostty` and inspect the headerbar.

## Corners

Adwaita rounds only the top two corners (`window.csd`) and clears them when the
window is tiled/maximized; they are zeroed here. The same is done globally in
`~/.config/gtk-4.0/gtk.css`; the copy here keeps `titlebar.css` usable standalone.

## Undershoot line

With `gtk-toolbar-style = flat`, libadwaita adds the `.undershoot-top` class to
`AdwToolbarView`, which turns the terminal's `GtkScrolledWindow` top undershoot
into a 1px line + 4px gradient: the dark line under the titlebar.

It is not a titlebar border, so:

- a fresh window (nothing scrolled out yet) does not show it;
- it appears as soon as the terminal has scrollback (`vadjustment > lower`) and
  disappears again at the top of scrollback (`Ctrl+Shift+Home`);
- switching to `raised` just turns it into a permanent shadow, and
  `scrollbar = never` does not help.

Zeroing `box-shadow` / `background` on the undershoot selectors removes it.

## Color presets

Enable exactly one with `gtk-custom-css` in `config.ghostty`:

| File | Titlebar | Text | Backdrop |
| --- | --- | --- | --- |
| `titlebar-colors-onedark.css` (current) | `#282c34` | `#abb2bf` | `#24282f` |
| `titlebar-colors-onedark-purple.css` | `#c678dd` | `#282c34` | `#b26cc7` |
| `titlebar-colors-default.css` | `#222226` | `#ffffff` | `#1e1e22` |

- The purple contrast is ~4.75:1; the terminal foreground `#abb2bf` would be only
  1.38:1 on purple, so it is deliberately not used.
- `default.css` captures the original Ghostty auto chrome (measured 2026-09-22)
  explicitly, so it survives libadwaita/Ghostty upgrades and can be switched back.
- A quieter dark purple is also viable: titlebar `#5c3a6e` + text `#abb2bf`
  (4.31:1); only one variable value needs to change.
- Overriding libadwaita's `--headerbar-*` variables from a user stylesheet had no
  effect (measured), so properties are written directly, with `:backdrop` added to
  keep a dimmer unfocused state.
- `window.csd` background matches the titlebar to hide the ~2px window strip above
  it.
- The 1px top outline can be dropped by uncommenting `window.csd { outline: none }`.

## Slimmer variant

The commented block in `titlebar.css` drops the bar to 8px and saves only ~10px
more: the next floors are the 16px icons, the window title text, and the
SplitButton arrow. Icon size does not affect height and is left alone.
