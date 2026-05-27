local theme = require("config.omawin-theme")

return {
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
