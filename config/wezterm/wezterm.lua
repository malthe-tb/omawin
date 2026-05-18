local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.default_prog = { "pwsh.exe", "-NoLogo" }

return config
