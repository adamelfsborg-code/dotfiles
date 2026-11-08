-- PEP 8: 4 spaces (global default is 2)
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4

-- run the current file / a REPL with the project's uv venv, in a tmux split
local function run_in_split(args, opts)
  vim.cmd("silent write")

  local file = vim.api.nvim_buf_get_name(0)
  local root = vim.fs.root(0, { "pyproject.toml", "uv.lock", ".git" }) or vim.fn.fnamemodify(file, ":h")
  local cmd = vim.list_extend({ "uv", "run", "python" }, args)
  table.insert(cmd, file)

  if not vim.env.TMUX then
    vim.cmd("botright vsplit")
    vim.fn.jobstart(cmd, { cwd = root, term = true })
    vim.cmd("startinsert")
    return
  end

  local script = '"$@"; echo; printf "[klar, tryck Enter]"; read _'
  local tmux = { "tmux", "split-window", "-h", "-l", "40%", "-c", root }
  if opts.keep_focus then
    table.insert(tmux, "-d")
  end
  vim.fn.system(vim.list_extend(tmux, { "sh", "-c", script, "sh", unpack(cmd) }))
end

vim.keymap.set("n", "<leader>pr", function()
  run_in_split({}, { keep_focus = true })
end, { buffer = true, desc = "Run python file in split" })

vim.keymap.set("n", "<leader>pi", function()
  run_in_split({ "-i" }, { keep_focus = false })
end, { buffer = true, desc = "Open python REPL with file loaded" })
