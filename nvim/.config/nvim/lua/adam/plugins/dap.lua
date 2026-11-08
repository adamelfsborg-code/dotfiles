return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "mfussenegger/nvim-dap-python",
  },
  keys = {
    { "<leader>bb", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
    { "<leader>bc", function() require("dap").continue() end, desc = "Start/continue debugging" },
    { "<leader>bo", function() require("dap").step_over() end, desc = "Step over" },
    { "<leader>bi", function() require("dap").step_into() end, desc = "Step into" },
    { "<leader>bO", function() require("dap").step_out() end, desc = "Step out" },
    { "<leader>bq", function() require("dap").terminate() end, desc = "Stop debugging" },
    { "<leader>bu", function() require("dapui").toggle() end, desc = "Toggle debugger UI" },
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    local dap_python = require("dap-python")

    dapui.setup()

    dap.listeners.after.event_initialized["dapui_config"] = dapui.open
    dap.listeners.before.event_terminated["dapui_config"] = dapui.close
    dap.listeners.before.event_exited["dapui_config"] = dapui.close

    -- debugpy runs from mason's venv, the debugged program from the project's .venv
    local debugpy_python = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "debugpy", "venv", "bin", "python")
    dap_python.setup(debugpy_python)

    dap_python.resolve_python = function()
      local root = vim.fs.root(0, { "pyproject.toml", "uv.lock", ".git" })
      local venv_python = root and vim.fs.joinpath(root, ".venv", "bin", "python")
      if venv_python and vim.fn.executable(venv_python) == 1 then
        return venv_python
      end

      return vim.fn.exepath("python3")
    end
  end,
}
