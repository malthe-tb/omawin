local theme = require("config.omawin-theme")

local plugins = {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
    },
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      contrast = "medium",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = theme.colorscheme,
    },
  },
}

if theme.monokai_pro_filter then
  table.insert(plugins, 1, {
    "gthelding/monokai-pro.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      filter = theme.monokai_pro_filter,
      override = function()
        return {
          NonText = { fg = "#948a8b" },
          MiniIconsGrey = { fg = "#948a8b" },
          MiniIconsRed = { fg = "#fd6883" },
          MiniIconsBlue = { fg = "#85dacc" },
          MiniIconsGreen = { fg = "#adda78" },
          MiniIconsYellow = { fg = "#f9cc6c" },
          MiniIconsOrange = { fg = "#f38d70" },
          MiniIconsPurple = { fg = "#a8a9eb" },
          MiniIconsAzure = { fg = "#a8a9eb" },
          MiniIconsCyan = { fg = "#85dacc" },
        }
      end,
    },
  })
end

return plugins
