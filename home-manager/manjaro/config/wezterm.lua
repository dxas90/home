local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.font = wezterm.font("CaskaydiaCove Nerd Font Mono")

config.font_size = 16

config.color_scheme = "Catppuccin Mocha"

config.window_background_opacity = 0.88

config.window_decorations = "RESIZE"

config.window_background_gradient = {
	interpolation = "Linear",

	orientation = "Vertical",

	blend = "Rgb",

	colors = {
		"#11111b",
		"#181825",
	},
}
config.keys = {
	{ key = "Enter", mods = "ALT", action = "DisableDefaultAssignment" },
	{ key = "f", mods = "CTRL", action = "DisableDefaultAssignment" },
	{ key = "f", mods = "CTRL|SHIFT", action = "DisableDefaultAssignment" },
	{ key = "k", mods = "CTRL|SHIFT", action = "DisableDefaultAssignment" },
	{ key = "LeftArrow", mods = "CTRL|SHIFT", action = "DisableDefaultAssignment" },
	{ key = "RightArrow", mods = "CTRL|SHIFT", action = "DisableDefaultAssignment" },
	{ key = "UpArrow", mods = "CTRL|SHIFT", action = "DisableDefaultAssignment" },
	{ key = "DownArrow", mods = "CTRL|SHIFT", action = "DisableDefaultAssignment" },
	{ key = "PageUp", mods = "SHIFT", action = "DisableDefaultAssignment" },
	{ key = "PageDown", mods = "SHIFT", action = "DisableDefaultAssignment" },
}

--config.mux_enable_ssh_agent = false

config.mux_env_remove = {
	"SSH_AUTH_SOCK",
	"SSH_CLIENT",
	"SSH_CONNECTION",
}

config.front_end = "WebGpu"

return config
