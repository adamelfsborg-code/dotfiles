-- render headings, lists, code blocks and tables in markdown buffers
-- (raw text comes back on the cursor line and in insert mode)
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>mr", "<cmd>RenderMarkdown toggle<CR>", ft = "markdown", desc = "Toggle markdown rendering" },
  },
  opts = {},
}
