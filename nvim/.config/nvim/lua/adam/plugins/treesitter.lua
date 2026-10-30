return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    local treesitter = require("nvim-treesitter.configs")
    require("nvim-treesitter.query_predicates")

    local query = require("vim.treesitter.query")
    local parser_install_dir = vim.fn.stdpath("data") .. "/treesitter"

    vim.opt.runtimepath:append(parser_install_dir)

    -- nvim 0.12 passes query captures as TSNode[] lists. Some nvim-treesitter
    -- compatibility predicates still expect a single TSNode, which can crash
    -- markdown/comment injections while inspecting TypeScript buffers.
    local function first_node(capture)
      if type(capture) == "table" then
        return capture[1]
      end

      return capture
    end

    local function parser_from_markdown_info_string(alias)
      local filetype = vim.filetype.match({ filename = "a." .. alias })
      return filetype
        or ({
          ex = "elixir",
          pl = "perl",
          sh = "bash",
          ts = "typescript",
          uxn = "uxntal",
        })[alias]
        or alias
    end

    local predicate_opts = { force = true, all = false }

    query.add_predicate("nth?", function(match, _, _, pred)
      local node = first_node(match[pred[2]])
      local n = tonumber(pred[3])
      if node and n and node:parent() and node:parent():named_child_count() > n then
        return node:parent():named_child(n) == node
      end

      return false
    end, predicate_opts)

    query.add_predicate("is?", function(match, _, bufnr, pred)
      local node = first_node(match[pred[2]])
      if not node then
        return true
      end

      local locals = require("nvim-treesitter.locals")
      local _, _, kind = locals.find_definition(node, bufnr)

      return vim.tbl_contains({ unpack(pred, 3) }, kind)
    end, predicate_opts)

    query.add_predicate("kind-eq?", function(match, _, _, pred)
      local node = first_node(match[pred[2]])
      if not node then
        return true
      end

      return vim.tbl_contains({ unpack(pred, 3) }, node:type())
    end, predicate_opts)

    query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
      local node = first_node(match[pred[2]])
      if not node then
        return
      end

      local type_attr_value = vim.treesitter.get_node_text(node, bufnr)
      local configured = {
        importmap = "json",
        module = "javascript",
        ["application/ecmascript"] = "javascript",
        ["text/ecmascript"] = "javascript",
      }

      if configured[type_attr_value] then
        metadata["injection.language"] = configured[type_attr_value]
      else
        local parts = vim.split(type_attr_value, "/", {})
        metadata["injection.language"] = parts[#parts]
      end
    end, predicate_opts)

    query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
      local node = first_node(match[pred[2]])
      if not node then
        return
      end

      local injection_alias = vim.treesitter.get_node_text(node, bufnr):lower()
      metadata["injection.language"] = parser_from_markdown_info_string(injection_alias)
    end, predicate_opts)

    query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
      local id = pred[2]
      local node = first_node(match[id])
      if not node then
        return
      end

      metadata[id] = metadata[id] or {}
      local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
      metadata[id].text = string.lower(text)
    end, predicate_opts)

    treesitter.setup({
      parser_install_dir = parser_install_dir,
      highlight = {
        enable = true,
      },
      indent = { enable = true },
      autotag = {
        enable = true,
      },
      auto_install = false,
      ensure_installed = {
        "json",
        "javascript",
        "typescript",
        "yaml",
        "html",
        "css",
        "markdown",
        "markdown_inline",
        "svelte",
        "gitignore",
        "dockerfile",
        "go",
        "lua",
        "vimdoc",
        "sql",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    })
  end,
}
