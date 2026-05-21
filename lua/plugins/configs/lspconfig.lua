require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    -- core
    "eslint",
    "html",
    "jsonls",
    "lua_ls",
    "basedpyright",
    "terraformls",
    "bashls",
    "tflint",
    "gopls",
    "jsonnet_ls",
    "starpls",

    -- React stack
    "vtsls",
    "tailwindcss",
    "emmet_ls",
    "cssls",
  },
})

local function find_bazel_workspace()
  local work = vim.fn.expand("~/work")
  for _, name in ipairs(vim.fn.readdir(work) or {}) do
    local dir = work .. "/" .. name
    if vim.fn.filereadable(dir .. "/tools/dprint/dprint") == 1 then
      return dir
    end
  end
  return nil
end

local workspace = find_bazel_workspace()

local M = {}
local map = vim.keymap.set

-- on_attach: keymaps
M.on_attach = function(_, bufnr)
  local function opts(desc) return { buffer = bufnr, desc = "LSP " .. desc } end

  map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
  map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
  map("n", "gi", vim.lsp.buf.implementation, opts "Go to implementation")
  map("n", "<leader>sh", vim.lsp.buf.signature_help, opts "Show signature help")
  map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
  map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")
  map("n", "<leader>wl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
    opts "List workspace folders")
  map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Go to type definition")
  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts "Code action")
  map("n", "gr", vim.lsp.buf.references, opts "Show references")
end

M.on_init = function(_, _) end

-- capabilities
M.capabilities = vim.lsp.protocol.make_client_capabilities()
M.capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = { properties = { "documentation", "detail", "additionalTextEdits" } },
}

-- defaults
M.defaults = function()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      M.on_attach(nil, args.buf)
    end,
  })

  -- Set default config for all LSP servers
  vim.lsp.config['*'] = {
    on_init = M.on_init,
    capabilities = M.capabilities,
  }

  -- Lua
  vim.lsp.config.lua_ls = {
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
        workspace = {
          library = {
            vim.fn.expand("$VIMRUNTIME/lua"),
            vim.fn.expand("$VIMRUNTIME/lua/vim/lsp"),
            vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy",
            "${3rd}/luv/library",
          },
          maxPreload = 100000,
          preloadFileSize = 10000,
        },
      },
    },
  }

  local venv_python = workspace and (workspace .. "/.venv/bin/python") or ""
  local python_path = vim.fn.filereadable(venv_python) == 1 and venv_python or vim.fn.exepath("python3")

  vim.lsp.config.basedpyright = {
    settings = {
      basedpyright = {
        pythonPath = python_path,
        analysis = {
          typeCheckingMode = "basic",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "openFilesOnly",
          logLevel = "Information",
          extraPaths = workspace and { workspace } or {},
          fileEnumerationTimeout = 300,
          inlayHints = {
            variableTypes = false,
            callArgumentNames = false,
          },
        },
      },
    },
  }

  -- React / TS core (VTSLS only)
  vim.lsp.config.vtsls = {
    on_init = nil, -- Override to disable on_init for vtsls
    settings = {
      vtsls = { enableMoveToFileCodeAction = true, tsserver = { globalPlugins = {} } },
      typescript = {
        inlayHints = {
          parameterNames = { enabled = "all" },
          variableTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
        },
        preferences = { importModuleSpecifier = "non-relative" },
        updateImportsOnFileMove = { enabled = "always" },
      },
      javascript = {
        inlayHints = {
          parameterNames = { enabled = "all" },
          variableTypes = { enabled = true },
        },
        preferences = { importModuleSpecifier = "non-relative" },
      },
    },
  }

  -- Emmet (React JSX/TSX snippets)
  vim.lsp.config.emmet_ls = {
    filetypes = { "html", "css", "javascriptreact", "typescriptreact", "less", "sass", "scss" },
  }

  -- JSON
  local ok_schemastore, schemastore = pcall(require, "schemastore")
  vim.lsp.config.jsonls = {
    settings = {
      json = {
        validate = { enable = true },
        format = { enable = true },
        schemas = ok_schemastore and schemastore.json.schemas() or {},
        schemaDownload = { enable = true },
        trace = { server = "verbose" },
      },
    },
  }

  -- ESLint
  vim.lsp.config.eslint = {
    on_attach = function(client, bufnr)
      M.on_attach(client, bufnr)
      -- Uncomment to auto-fix on save:
      vim.api.nvim_create_autocmd("BufWritePre", { buffer = bufnr, command = "EslintFixAll" })
    end,
  }

  -- Terraform (include Terragrunt .hcl files)
  vim.lsp.config.terraformls = {
    filetypes = { "terraform", "terraform-vars", "hcl" },
  }

  -- Go (disable gopackagesdriver — bazel workspace causes issues with default driver)
  vim.lsp.config.gopls = {
    filetypes = { "go", "gomod", "gosum", "gowork", "gotmpl" },
    cmd_env = { GOPACKAGESDRIVER = "" },
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
        },
        staticcheck = true,
        gofumpt = true,
      },
    },
  }

  -- Bash (prefer workspace-pinned shellcheck if present)
  local workspace_shellcheck = workspace and (workspace .. "/tools/dotslash/bin/shellcheck") or ""
  vim.lsp.config.bashls = {
    settings = {
      bashIde = {
        shellcheckPath = vim.fn.filereadable(workspace_shellcheck) == 1 and workspace_shellcheck or "shellcheck",
      },
    },
  }

  -- CSS
  vim.lsp.config.cssls = {}

  -- HTML
  vim.lsp.config.html = {}

  -- Tailwind CSS
  vim.lsp.config.tailwindcss = {
    filetypes = {
      'html', 'css', 'scss', 'less', 'postcss',
      'javascript', 'javascriptreact',
      'typescript', 'typescriptreact',
      'vue', 'svelte', 'templ',
    },
    root_dir = function(bufnr, on_dir)
      local fname = vim.api.nvim_buf_get_name(bufnr)
      local root = vim.fs.find({
        'tailwind.config.js',
        'tailwind.config.cjs',
        'tailwind.config.mjs',
        'tailwind.config.ts',
        'postcss.config.js',
        'postcss.config.cjs',
        'postcss.config.mjs',
        'postcss.config.ts',
      }, { path = fname, upward = true })[1]
      on_dir(root and vim.fs.dirname(root) or nil)
    end,
  }

  -- Jsonnet
  vim.lsp.config.jsonnet_ls = {}

  -- Starlark / Bazel (BUILD, .bzl, WORKSPACE)
  vim.lsp.config.starpls = {}

  -- TFLint (Terraform linter)
  vim.lsp.config.tflint = {}

  -- Enable all configured LSP servers
  local servers = {
    'lua_ls',
    'terraformls',
    'bashls',
    'tflint',
    'basedpyright',
    'vtsls',
    'tailwindcss',
    'emmet_ls',
    'cssls',
    'html',
    'jsonls',
    'eslint',
    "gopls",
    "jsonnet_ls",
    "starpls",
  }

  for _, server in ipairs(servers) do
    vim.lsp.enable(server)
  end
end

return M
