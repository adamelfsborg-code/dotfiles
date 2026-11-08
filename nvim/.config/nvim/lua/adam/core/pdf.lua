-- open PDFs as plain text (pdftotext -layout from poppler) instead of binary
local group = vim.api.nvim_create_augroup("adam_pdf", { clear = true })

-- show the PDF in tdf (kitty graphics) in a tmux split next to nvim
local function open_in_tdf(file)
  if vim.fn.executable("tdf") == 0 then
    vim.notify("tdf saknas: brew install tdf", vim.log.levels.WARN)
    return
  end

  if vim.env.TMUX then
    vim.fn.system({ "tmux", "split-window", "-h", "-l", "50%", "tdf", file })
  else
    vim.cmd("botright vsplit")
    vim.fn.jobstart({ "tdf", file }, { term = true })
    vim.cmd("startinsert")
  end
end

vim.api.nvim_create_autocmd("BufReadCmd", {
  group = group,
  pattern = "*.pdf",
  callback = function(args)
    local file = vim.fn.fnamemodify(args.file, ":p")
    local buf = args.buf

    if vim.fn.executable("pdftotext") == 0 then
      vim.notify("pdftotext saknas: brew install poppler", vim.log.levels.ERROR)
      return
    end

    local result = vim.system({ "pdftotext", "-layout", file, "-" }, { text = true }):wait()
    if result.code ~= 0 then
      vim.notify("pdftotext: " .. (result.stderr or ""), vim.log.levels.ERROR)
      return
    end

    -- no swap file: the buffer is a read-only view, and the PDF may be open elsewhere
    vim.bo[buf].swapfile = false
    vim.bo[buf].buftype = "nowrite"

    -- pages are separated by form feeds; keep them as empty lines
    local text = result.stdout:gsub("\f", "\n")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n", { plain = true }))

    vim.bo[buf].modified = false
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    vim.bo[buf].filetype = "pdftext"

    vim.keymap.set("n", "<leader>po", function()
      open_in_tdf(file)
    end, { buffer = buf, desc = "Open PDF in tdf (tmux split)" })
  end,
})
