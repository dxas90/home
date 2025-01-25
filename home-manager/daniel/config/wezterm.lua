local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.font = wezterm.font 'CaskaydiaCove Nerd Font Mono'

config.font_size = 16

config.color_scheme = 'Catppuccin Mocha'

config.window_background_opacity = 0.88

config.window_decorations = "RESIZE"

config.window_background_gradient = {
  interpolation = 'Linear',

  orientation = 'Vertical',

  blend = 'Rgb',

  colors = {
    '#11111b',
    '#181825',
  },
}
--config.webgpu_preferred_adapter = {
--  backend = 'Vulkan',
--  device = 9479,
--  device_type = 'DiscreteGpu',
--  driver = 'NVIDIA',
--  driver_info = '550.135',
--  name = 'NVIDIA GeForce RTX 3050',
--  vendor = 4318,
--}
config.front_end = 'WebGpu'

--config.use_fancy_tab_bar = false

return config

