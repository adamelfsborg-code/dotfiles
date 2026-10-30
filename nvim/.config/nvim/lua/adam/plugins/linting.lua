return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      svelte = { "eslint_d" },
      go = { "golangcilint" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
    local function lint_current_buffer()
      if vim.bo.buftype ~= "" or vim.bo.filetype == "" then
        return
      end

      local ok, err = pcall(lint.try_lint)
      if ok or not tostring(err):match("ENOENT") then
        return
      end
    end

    vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = lint_current_buffer,
    })

    vim.keymap.set("n", "<leader>l", function()
      lint_current_buffer()
    end, { desc = "Trigger linting for current file" })
  end,
}
