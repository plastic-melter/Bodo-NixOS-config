local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config = {
  front_end = "Software", --wgpu and ogl are both broken, 2026-08-13, unknown why
  automatically_reload_config = true,
  harfbuzz_features = { 'calt = 0', 'clig = 0', 'liga = 0' },
  enable_tab_bar = false,
  window_close_confirmation = "NeverPrompt", 
  window_decorations = "NONE",
  default_cursor_style = "SteadyBlock",
  color_scheme = "neobones_dark",
  font_size =12.0,
  font = wezterm.font_with_fallback({
    { family = "JetBrains Mono", weight = "Bold" },
    "Symbols Nerd Font",
  }),
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },
  window_background_gradient = {
    orientation = "Vertical";
    colors = {
      '#__BG__',
    };
  };
--[[
  background = {
    {
      source = {
        File = "/etc/nixos/wallpapers/watercaustic.jpeg",
      },
      hsb = {
        hue = 1.0,
        saturation = 1.0,
        brightness = 0.0,
      },
    },
    {
      source = {
        Color = "__BG__",
      },
      width = "100%",
      height = "100%",
      opacity = 0.8,
    },
  }, 
  ]]--
}

return config
