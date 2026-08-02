-- Hyprland config, Lua format (0.55+)
-- Migrated from hyprland.conf

local mod = "SUPER"
local scripts = "/etc/nixos/dotfiles/scripts"

-------------------------------
-- Keyboard/touchpad
-------------------------------

hl.config({
  input = {
    kb_layout     = "jp",
    kb_model      = "jp106",
    follow_mouse  = 1,
    sensitivity   = 0,          -- keep global neutral
    accel_profile = "adaptive", -- "adaptive" or "flat"
    touchpad = {
      natural_scroll = true,
    },
    scroll_method = "on_button_down",
    scroll_button = 274,
  },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

for _, name in ipairs({
  "lite-on-technology-corp.-thinkpad-usb-keyboard-with-trackpoint-1",
  "lite-on-technology-corp.-thinkpad-usb-keyboard-with-trackpoint-3",
}) do
  hl.device({
    name          = name,
    sensitivity   = 1.0, -- 1.0 = max
    accel_profile = "adaptive",
  })
end

-------------------------------
-- Gaps, border colors
-------------------------------

hl.config({
  general = {
    gaps_out    = 0,
    gaps_in     = 1,
    border_size = 0,
    col = {
      active_border   = { colors = { "rgba(__BORDER_ACTIVE2__ff)", "rgba(__BORDER_ACTIVE__ff)" }, angle = 45 },
      inactive_border = "rgba(__BORDER_INACTIVE__ff)",
    },
    layout = "dwindle",
  },
})

-------------------------------
-- Rice/swag
-------------------------------

hl.config({
  decoration = {
    rounding = 8,
    blur = {
      enabled           = true,
      size              = 3,
      passes            = 1,
      new_optimizations = true,
    },
    -- shadow = { enabled = true, range = 4, render_power = 3, color = "rgba(1a1a1aee)" },
    active_opacity   = 1.0,
    inactive_opacity = 0.85,
  },
})

-------------------------------
-- Animations
-------------------------------

hl.config({ animations = { enabled = true } })

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })

-------------------------------
-- Tiling / misc categories
-------------------------------

hl.config({
  dwindle = {
    preserve_split = true,
    smart_split    = true,
  },

  ecosystem = {
    no_update_news      = true,
    no_donation_nag     = true,
    enforce_permissions = false, -- dont priv-check apps that try to do stuff w/ hyprland
  },

  -- Touchpad gestures
  gestures = {
    workspace_swipe_distance     = 500,
    workspace_swipe_cancel_ratio = 0.15,
  },

  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo   = true,
    vrr                     = 2, -- Use VRR only when fullscreened, such as games
  },
})

-------------------------------
-- Window rules
-------------------------------

-- things to float
for _, class in ipairs({
  "thunar",
  "imv",
  "pavucontrol",
  "org\\.pulseaudio\\.pavucontrol",
  "vlc",
  "org\\.kde\\.kcolorchooser",
  "steam",
  ".blueman-manager-wrapped",
  ".blueman-manager",
  "dolphin-emu",
  "wine",
  "waypaper",
}) do
  hl.window_rule({ match = { class = class }, float = true })
end
hl.window_rule({ match = { title = "Lutris" }, float = true })

-- special keybinds to launch in float
hl.window_rule({ match = { class = "floating-wezterm" },       float = true, center = true })
hl.window_rule({ match = { class = "floating-wezterm-large" }, float = true, center = true })

-- default floating sizes
hl.window_rule({ match = { class = "floating-wezterm" },              size = { 1100, 620 } })
hl.window_rule({ match = { class = "floating-wezterm-large" },        size = { 1600, 620 } })
hl.window_rule({ match = { class = "thunar" },                        size = { 1000, 900 } })
hl.window_rule({ match = { class = "firefox" },                       size = { 1450, 1600 } })
hl.window_rule({ match = { class = "vlc" },                           size = { 1920, 1200 } })
hl.window_rule({ match = { title = "Lutris" },                        size = { 1280, 800 } })
hl.window_rule({ match = { class = "org\\.pulseaudio\\.pavucontrol" }, size = { 1280, 1400 } })
hl.window_rule({ match = { class = "org\\.kde\\.kcolorchooser" },      size = { 1280, 800 } })
hl.window_rule({ match = { class = ".blueman-manager-wrapped" },      size = { 450, 500 } })
hl.window_rule({ match = { class = ".blueman-manager" },              size = { 450, 500 } })
hl.window_rule({ match = { class = "dolphin-emu" },                   size = { 1280, 800 } })
hl.window_rule({ match = { class = "waypaper" },                      size = { 900, 1300 } })

-------------------------------
-- Setup stuff
-------------------------------

-- X210Ai internal display
hl.monitor({ output = "eDP-1", mode = "2560x1600@165", position = "0x0", scale = 1 })
-- 2560x1600 120Hz travel monitor
hl.monitor({ output = "desc:XRJ HQ160", mode = "2560x1600@120", position = "auto", scale = 1 })
-- LG C2 OLED
hl.monitor({ output = "desc:LG Electronics LG TV SSCR2 0x01010101", mode = "3840x2160@120", position = "auto", scale = 1 })

hl.env("XCURSOR_SIZE", "18")
hl.env("XCURSOR_THEME", "Adwaita")

-------------------------------
-- Keybinds
-------------------------------

-- App launching
hl.bind(mod .. " + Return",         hl.dsp.exec_cmd("wezterm"))
hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd("wezterm start --always-new-process --class floating-wezterm"))
hl.bind(mod .. " + M",              hl.dsp.exec_cmd("wezterm start --always-new-process --class floating-wezterm-large -e rmpc"))
hl.bind(mod .. " + SHIFT + M",      hl.dsp.exec_cmd("wezterm start --always-new-process --class floating-wezterm-large -e rmpc"))
hl.bind(mod .. " + Z",              hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mod .. " + SHIFT + Z",      hl.dsp.exec_cmd("nwg-drawer -ovl"))
hl.bind(mod .. " + R",              hl.dsp.exec_cmd("nwg-drawer -ovl"))
hl.bind(mod .. " + SHIFT + L",      hl.dsp.exec_cmd(scripts .. "/lock.sh"))
hl.bind(mod .. " + SHIFT + C",      hl.dsp.exec_cmd("kcolorchooser"))
hl.bind(mod .. " + E",              hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + Q",              hl.dsp.exec_cmd("ags toggle panel"))
hl.bind(mod .. " + H",              hl.dsp.exec_cmd("ags toggle help"))

-- Commands
hl.bind(mod .. " + SHIFT + Q",     hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + E",     hl.dsp.exec_cmd("wlogout"))
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + space",         hl.dsp.window.pseudo())
hl.bind(mod .. " + C",             hl.dsp.window.center())

-- Function keys
hl.bind("Print",                       hl.dsp.exec_cmd("hyprshot -m output -t 2000"))
hl.bind(mod .. " + Print",             hl.dsp.exec_cmd("hyprshot -m region -t 2000"))
hl.bind(mod .. " + SHIFT + Print",     hl.dsp.exec_cmd("hyprshot -m window -t 2000"))
hl.bind("XF86SelectiveScreenshot",     hl.dsp.exec_cmd("hyprshot -m window -t 2000"))

-- WM: switch workspaces
hl.bind(mod .. " + A",            hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + S",            hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + ALT + left",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + ALT + right",  hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + Prior",         hl.dsp.exec_cmd("hyprnome --previous"))
hl.bind(mod .. " + Next",          hl.dsp.exec_cmd("hyprnome"))
hl.bind(mod .. " + SHIFT + Prior", hl.dsp.exec_cmd("hyprnome --previous --move"))
hl.bind(mod .. " + SHIFT + Next",  hl.dsp.exec_cmd("hyprnome --move"))

-- WM: switch to / send to workspace 1-5
for i = 1, 5 do
  hl.bind(mod .. " + " .. i,           hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. i,   hl.dsp.window.move({ workspace = i, follow = false })) -- silent
end

-- WM: change focus
local dirs = { left = "left", right = "right", up = "up", down = "down", h = "left", l = "right", k = "up", j = "down" }
for key, dir in pairs(dirs) do
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = dir }))
end

-- WM: scroll workspaces
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e+1" }))

-- WM: toggle fullscreen
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())

-- WM: swap windows
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "down" }))
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))

-- WM: move windows (floating)
-- NOTE: these keys are also bound above to swapwindow, same as the old config
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ x = 0,    y = -100, relative = true }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ x = 0,    y = 100,  relative = true }))
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ x = -100, y = 0,    relative = true }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ x = 100,  y = 0,    relative = true }))

-- WM: move/resize with mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Resize windows using keyboard
local resizes = {
  up    = {  0, -50 }, down  = {  0,  50 },
  left  = { -50,  0 }, right = {  50,  0 },
  k     = {  0, -50 }, j     = {  0,  50 },
  h     = { -50,  0 }, l     = {  50,  0 },
}
for key, d in pairs(resizes) do
  hl.bind(mod .. " + CTRL + " .. key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
end

-- Audio
hl.bind("XF86AudioMute",           hl.dsp.exec_cmd(scripts .. "/mute.sh"),               { locked = true })
hl.bind("XF86AudioMicMute",        hl.dsp.exec_cmd(scripts .. "/micmute.sh"),            { locked = true })
hl.bind("XF86MonBrightnessUp",     hl.dsp.exec_cmd(scripts .. "/brightnessctl.sh up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",   hl.dsp.exec_cmd(scripts .. "/brightnessctl.sh down"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume",    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioNext",           hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",           hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioPlay",           hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

-- Misc
hl.bind(mod .. " + X", hl.dsp.exec_cmd("if systemctl --user is-active --quiet waybar; then systemctl --user stop waybar; else systemctl --user start waybar; fi"))
hl.bind("XF86Display",             hl.dsp.exec_cmd(scripts .. "/screenres.sh"))
hl.bind("XF86LinkPhone",           hl.dsp.exec_cmd(scripts .. "/p14sg6-120hz.sh"))
hl.bind("XF86WLAN",                hl.dsp.exec_cmd(scripts .. "/XF86WLAN.sh"))
hl.bind("XF86Favorites",           hl.dsp.exec_cmd("nwg-drawer -is 94 -ovl -c 6 -lang ja"))
hl.bind("Cancel",                  hl.dsp.exec_cmd("wlogout"))
hl.bind("XF86Go",                  hl.dsp.exec_cmd(scripts .. "/XF86Go.sh"))
hl.bind("XF86Messenger",           hl.dsp.exec_cmd(scripts .. "/XF86Messenger.sh"))
hl.bind(mod .. " + ALT + E", function()
  hl.monitor({ output = "HDMI-A-1", mode = "1280x768" })
end)
hl.bind(mod .. " + V", hl.dsp.exec_cmd("nwg-clipman"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd(scripts .. "/theme.sh -y"))

-------------------------------
-- Startup programs
-------------------------------

hl.on("hyprland.start", function()
  hl.exec_cmd("hypridle")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,ssh")
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("nm-applet")
end)
