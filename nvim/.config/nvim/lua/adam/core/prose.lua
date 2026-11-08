-- shared settings for buffers that hold prose rather than code
local M = {}

function M.setup()
  vim.opt_local.wrap = true -- soft wrap long lines (global default is nowrap)
  vim.opt_local.linebreak = true -- break at word boundaries, not mid-word
  vim.opt_local.breakindent = true -- keep the indent of wrapped list items

  -- move by screen line on wrapped text, keep counts (5j) working by real line
  vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { buffer = true, expr = true })
  vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { buffer = true, expr = true })
end

return M
