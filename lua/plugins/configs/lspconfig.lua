require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    -- core
    "eslint",
    "html",
    "jsonls",
    "lua_ls",
    "pyright",
    "terraformls",
    "tflint",
    "gopls",

    -- React stack
    "vtsls",
    "tailwindcss",
    "emmet_ls",
    "cssls",
  },
})

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

-- disable semanticTokens
M.on_init = function(client, _)
  if client.supports_method "textDocument/semanticTokens" then
    client.server_capabilities.semanticTokensProvider = nil
  end
end

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
  -- Set default config for all LSP servers
  vim.lsp.config['*'] = {
    on_attach = M.on_attach,
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

  -- Python (Poetry env)
  local poetry_env_ok, poetry_env_path = pcall(function()
    local p = vim.fn.systemlist("poetry env info -p")[1]
    return (p and #p > 0) and (p .. "/bin/python") or nil
  end)

  vim.lsp.config.pyright = {
    settings = {
      python = {
        pythonPath = poetry_env_ok and poetry_env_path or vim.fn.exepath("python3"),
        analysis = {
          typeCheckingMode = "strict",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "openFilesOnly",
          logLevel = "Information",
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
  
  -- Go
  vim.lsp.config.gopls = {
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
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

  -- CSS
  vim.lsp.config.cssls = {}

  -- HTML
  vim.lsp.config.html = {}

  -- Tailwind CSS
  vim.lsp.config.tailwindcss = {}

  -- TFLint (Terraform linter)
  vim.lsp.config.tflint = {}

  -- Enable all configured LSP servers
  local servers = {
    'lua_ls',
    'terraformls',
    'tflint',
    'pyright',
    'vtsls',
    'tailwindcss',
    'emmet_ls',
    'cssls',
    'html',
    'jsonls',
    'eslint',
    "gopls",
  }

  for _, server in ipairs(servers) do
    vim.lsp.enable(server)
  end
end

return M
