return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "catppuccin/nvim", -- make sure this is installed
  },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status")
    local cp = require("catppuccin.palettes").get_palette("mocha")

    lualine.setup({
      options = {
        theme = "catppuccin-mocha",
      },
      sections = {
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = { fg = cp.peach },
          },
          { "encoding" },
          { "fileformat" },
          { "filetype" },
        },
      },
    })
  end,
}
