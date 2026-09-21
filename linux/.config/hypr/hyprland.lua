-- NVIDIA / Wayland
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- Programs
local mainMod = "SUPER"
local terminal = "ghostty"
local fileManager = "nautilus"
local menu = "hyprlauncher"
local scrollingDirection = "right"

local bracketDirection = scrollingDirection == "left" and { "next", "prev" }
  or scrollingDirection == "up" and { "next", "prev" }
  or { "prev", "next" }

local function focus(direction)
  if scrollingDirection == "left" or scrollingDirection == "right" then
    if direction == "left" or direction == "right" then
      return hl.dsp.layout("focus " .. (direction == "left" and "l" or "r"))
    end
  elseif direction == "up" or direction == "down" then
    local logicalDirection = scrollingDirection == "down"
      and (direction == "down" and "r" or "l")
      or (direction == "down" and "l" or "r")
    return hl.dsp.layout("focus " .. logicalDirection)
  end
  return hl.dsp.focus({ direction = direction })
end

-- Keybinds
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))

hl.bind(mainMod .. " + W", hl.dsp.window.close())

hl.bind(mainMod .. " + SHIFT + Q",
  hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.exit()'")
)

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))

hl.bind(
  mainMod .. " + V",
  hl.dsp.window.float({ action = "toggle" })
)

hl.bind(mainMod .. " + BRACKETLEFT", hl.dsp.layout("consume_or_expel " .. bracketDirection[1]))
hl.bind(mainMod .. " + BRACKETRIGHT", hl.dsp.layout("consume_or_expel " .. bracketDirection[2]))

hl.bind(mainMod .. " + LEFT", focus("left"))
hl.bind(mainMod .. " + DOWN", focus("down"))
hl.bind(mainMod .. " + UP", focus("up"))
hl.bind(mainMod .. " + RIGHT", focus("right"))
hl.bind(mainMod .. " + H", focus("left"))
hl.bind(mainMod .. " + J", focus("down"))
hl.bind(mainMod .. " + K", focus("up"))
hl.bind(mainMod .. " + L", focus("right"))

hl.bind(mainMod .. " + CTRL + LEFT",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + RIGHT", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + UP",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + DOWN",  hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ direction = "right" }))

hl.bind(mainMod .. " + PAGE_DOWN", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + PAGE_UP", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + PAGE_DOWN", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mainMod .. " + CTRL + PAGE_UP", hl.dsp.window.move({ workspace = "e-1" }))

for i = 1, 9 do
  hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
end

-- General
hl.config({
  general = {
    border_size = 2,
    gaps_in = 2,
    gaps_out = 4,
    layout = "scrolling",
  },

  scrolling = {
    direction = scrollingDirection,
    column_width = 0.5,
    focus_fit_method = 1,
    follow_focus = true,
    follow_min_visible = 0.5,
    explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
    wrap_focus = false,
    wrap_swapcol = false,
    fullscreen_on_one_column = true,
  },
})

hl.curve("easeOutQuint", {
  type = "bezier",
  points = {
    {0.23, 1 },
    {0.32, 1 },
  }
})

hl.curve("smoothstep", {
  type = "bezier",
  points = {
    {0.333333, 0 },
    {0.666667, 1 },
  }
})

hl.animation({
  leaf = "windows",
  enabled = true,
  speed = 2,
  bezier = "smoothstep",
})

hl.animation({
  leaf = "windowsIn",
  enabled = true,
  speed = 2,
  bezier = "smoothstep",
  style = "popin 87%",
})

hl.animation({
  leaf = "windowsOut",
  enabled = true,
  speed = 2,
  bezier = "smoothstep",
  style = "popin 87%",
})

-- Input
hl.config({
  input = {
    kb_layout = "us",
    repeat_rate = 30,
    repeat_delay = 300,
  },
})

-- Monitor
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1,
  transform = 3,
})
