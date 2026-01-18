local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

config = {
  automatically_reload_config = true,
  harfbuzz_features = { 'calt = 0', 'clig = 0', 'liga = 0' },
  enable_tab_bar = false,
  window_close_confirmation = "NeverPrompt", 
  window_decorations = "NONE",
  default_cursor_style = "SteadyBlock",
  color_scheme = "neobones_dark",
  --color_scheme = "NvimDark",
  font_size =12.0,
  font = wezterm.font("JetBrains Mono", { weight = "Bold" }),
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },
  window_background_gradient = {
    orientation = "Vertical";
    colors = {
      '#1d1e2e',
    };
  };
  background = {
    {
      source = {
         File = "/etc/nixos/dotfiles/images/utau.jpg",
      },
      hsb = {
        hue = 1.0,
       saturation = 1.0,
        brightness = 0.01,
      },
    },
    {
      source = {
        --Color = "#2e3440",
        Color = "131728",
      },
      width = "100%",
      height = "100%",
      opacity = 0.9,
    },
  },
}

return config
