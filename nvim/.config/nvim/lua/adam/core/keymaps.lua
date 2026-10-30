vim.g.mapleader = " "

local keymap = vim.keymap

local function diagnostic_jump(count, severity)
  return function()
    vim.diagnostic.jump({
      count = count,
      severity = severity,
      on_jump = function()
        vim.diagnostic.open_float()
      end,
    })
  end
end

-- exit insert mode 
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })


-- window management

-- splits
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- tabs
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

-- diagnostics
keymap.set("n", "[d", diagnostic_jump(-1), { desc = "Go to previous diagnostic" })
keymap.set("n", "]d", diagnostic_jump(1), { desc = "Go to next diagnostic" })
keymap.set("n", "[w", diagnostic_jump(-1, vim.diagnostic.severity.WARN), { desc = "Go to previous warning" })
keymap.set("n", "]w", diagnostic_jump(1, vim.diagnostic.severity.WARN), { desc = "Go to next warning" })
keymap.set("n", "[e", diagnostic_jump(-1, vim.diagnostic.severity.ERROR), { desc = "Go to previous error" })
keymap.set("n", "]e", diagnostic_jump(1, vim.diagnostic.severity.ERROR), { desc = "Go to next error" })
