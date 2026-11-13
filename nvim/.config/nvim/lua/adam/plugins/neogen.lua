return {
  "danymat/neogen",
  dependencies = { "nvim-treesitter/nvim-treesitter", "L3MON4D3/LuaSnip" },
  cmd = "Neogen",
  keys = {
    {
      "<leader>nd",
      function()
        require("neogen").generate()
      end,
      desc = "Generate docstring",
    },
  },
  opts = {
    -- placeholders become LuaSnip jumps, so <Tab>/<S-Tab> moves between them
    snippet_engine = "luasnip",
    languages = {
      python = { template = { annotation_convention = "google_docstrings" } },
    },
  },
}
