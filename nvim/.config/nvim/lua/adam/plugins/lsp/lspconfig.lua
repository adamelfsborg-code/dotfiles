return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  config = function()
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

    local function typescript_root_dir(bufnr)
      local root_markers = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
      root_markers = vim.fn.has("nvim-0.11.3") == 1 and { root_markers, { ".git" } }
        or vim.list_extend(root_markers, { ".git" })

      local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
      local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })
      local project_root = vim.fs.root(bufnr, root_markers)

      if deno_lock_root and (not project_root or #deno_lock_root > #project_root) then
        return nil
      end
      if deno_root and (not project_root or #deno_root >= #project_root) then
        return nil
      end

      return project_root or vim.fn.getcwd()
    end

    local function find_local_tsgo(root_dir)
      if not root_dir then
        return nil
      end

      local local_cmd = vim.fs.joinpath(root_dir, "node_modules", ".bin", "tsgo")
      if vim.fn.executable(local_cmd) == 1 then
        return local_cmd
      end

      return nil
    end

    local function find_mason_bin(cmd)
      local mason_cmd = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin", cmd)
      if vim.fn.executable(mason_cmd) == 1 then
        return mason_cmd
      end

      return nil
    end

    local function find_executable(cmd, root_dir)
      if root_dir then
        local local_cmd = vim.fs.joinpath(root_dir, "node_modules", ".bin", cmd)
        if vim.fn.executable(local_cmd) == 1 then
          return local_cmd
        end
      end

      local global_cmd = vim.fn.exepath(cmd)
      if global_cmd ~= "" then
        return global_cmd
      end

      return find_mason_bin(cmd)
    end

    local function find_tsgo(root_dir)
      local local_cmd = find_local_tsgo(root_dir)
      if local_cmd then
        return local_cmd
      end

      local global_cmd = vim.fn.exepath("tsgo")
      if global_cmd ~= "" then
        return global_cmd
      end

      return find_mason_bin("tsgo")
    end

    local function has_package_dependency(root_dir, package_name)
      local package_json = vim.fs.joinpath(root_dir, "package.json")
      if vim.uv.fs_stat(package_json) == nil then
        return false
      end

      local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_json), "\n"))
      if not ok or type(decoded) ~= "table" then
        return false
      end

      local dependency_fields = {
        "dependencies",
        "devDependencies",
        "peerDependencies",
        "optionalDependencies",
      }

      for _, field in ipairs(dependency_fields) do
        local dependencies = decoded[field]
        if type(dependencies) == "table" and dependencies[package_name] ~= nil then
          return true
        end
      end

      return false
    end

    local function has_any_file(root_dir, names)
      for _, name in ipairs(names) do
        if vim.uv.fs_stat(vim.fs.joinpath(root_dir, name)) ~= nil then
          return true
        end
      end

      return false
    end

    local function tailwind_root_dir(bufnr)
      local root_dir = typescript_root_dir(bufnr)
      if not root_dir then
        return nil
      end

      if has_any_file(root_dir, {
        "tailwind.config.js",
        "tailwind.config.cjs",
        "tailwind.config.mjs",
        "tailwind.config.ts",
        "postcss.config.js",
        "postcss.config.cjs",
        "postcss.config.mjs",
        "postcss.config.ts",
      }) then
        return root_dir
      end

      if has_package_dependency(root_dir, "tailwindcss")
        or has_package_dependency(root_dir, "@tailwindcss/postcss")
        or has_package_dependency(root_dir, "@tailwindcss/vite")
      then
        return root_dir
      end

      return nil
    end

    local function path_is_within(root_dir, file_path)
      if type(root_dir) ~= "string" or type(file_path) ~= "string" then
        return false
      end

      local normalized_root = vim.fs.normalize(root_dir)
      local normalized_file = vim.fs.normalize(file_path)

      return normalized_file == normalized_root or vim.startswith(normalized_file, normalized_root .. "/")
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }

        opts.desc = "Show LSP reference"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

        opts.desc = "See avaiable code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>na", vim.lsp.buf.rename, opts)

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

        opts.desc = "Go to line diagnostic"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", diagnostic_jump(-1), opts)

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", diagnostic_jump(1), opts)

        opts.desc = "Show documentaiton for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts)

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
      end,
    })

    local capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
      textDocument = {
        completion = {
          dynamicRegistration = false,
          completionItem = {
            snippetSupport = true,
            commitCharactersSupport = true,
            deprecatedSupport = true,
            preselectSupport = true,
            tagSupport = {
              valueSet = { 1 },
            },
            insertReplaceSupport = true,
            resolveSupport = {
              properties = {
                "documentation",
                "additionalTextEdits",
                "insertTextFormat",
                "insertTextMode",
                "command",
              },
            },
            insertTextModeSupport = {
              valueSet = { 1, 2 },
            },
            labelDetailsSupport = true,
          },
          contextSupport = true,
          insertTextMode = 1,
          completionList = {
            itemDefaults = {
              "commitCharacters",
              "editRange",
              "insertTextFormat",
              "insertTextMode",
              "data",
            },
          },
        },
      },
    })

    vim.diagnostic.config({
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = " ",
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.HINT] = "󰠠 ",
          [vim.diagnostic.severity.INFO] = " ",
        },
      },
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
      group = vim.api.nvim_create_augroup("UserSvelteJsTsSync", { clear = true }),
      pattern = { "*.js", "*.ts" },
      callback = function(ctx)
        local file_path = vim.fn.fnamemodify(ctx.match, ":p")

        for _, client in ipairs(vim.lsp.get_clients({ name = "svelte" })) do
          if path_is_within(client.config.root_dir, file_path) then
            client:notify("$/onDidChangeTsOrJsFile", { uri = vim.uri_from_fname(file_path) })
          end
        end
      end,
    })

    local servers = {
      tsgo = {
        capabilities = {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = false,
            },
          },
        },
        cmd = function(dispatchers, config)
          local cmd = find_tsgo((config or {}).root_dir)
          if not cmd then
            return
          end

          return vim.lsp.rpc.start({ cmd, "--lsp", "--stdio" }, dispatchers)
        end,
        root_dir = function(bufnr, on_dir)
          local root_dir = typescript_root_dir(bufnr)
          if not root_dir or not find_local_tsgo(root_dir) then
            return
          end

          on_dir(root_dir)
        end,
      },
      ts_ls = {
        cmd = function(dispatchers, config)
          local cmd = find_executable("typescript-language-server", (config or {}).root_dir)
          if not cmd then
            return
          end

          return vim.lsp.rpc.start({ cmd, "--stdio" }, dispatchers)
        end,
        root_dir = function(bufnr, on_dir)
          local root_dir = typescript_root_dir(bufnr)
          if not root_dir or find_local_tsgo(root_dir) then
            return
          end

          on_dir(root_dir)
        end,
      },
      html = {},
      cssls = {},
      tailwindcss = {
        cmd = function(dispatchers, config)
          local cmd = find_executable("tailwindcss-language-server", (config or {}).root_dir)
          if not cmd then
            return
          end

          return vim.lsp.rpc.start({ cmd, "--stdio" }, dispatchers)
        end,
        root_dir = function(bufnr, on_dir)
          local root_dir = tailwind_root_dir(bufnr)
          if not root_dir then
            return
          end

          on_dir(root_dir)
        end,
      },
      svelte = {
        cmd = { find_mason_bin("svelteserver") or "svelteserver", "--stdio" },
      },
      emmet_ls = {
        cmd = { find_mason_bin("emmet-ls") or "emmet-ls", "--stdio" },
        filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
      },
      gopls = {
        cmd = { find_mason_bin("gopls") or "gopls" },
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
          },
        },
      },
      lua_ls = {
        cmd = { find_mason_bin("lua-language-server") or "lua-language-server" },
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            completion = {
              callSnippet = "Replace",
            },
          },
        },
      },
    }

    for server_name, config in pairs(servers) do
      config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, config.capabilities or {})
      vim.lsp.config(server_name, config)
      vim.lsp.enable(server_name)
    end
  end,
}
