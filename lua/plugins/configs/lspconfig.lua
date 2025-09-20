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
  local lsp = require("lspconfig")

  -- Lua
  lsp.lua_ls.setup {
    on_attach = M.on_attach,
    capabilities = M.capabilities,
    on_init = M.on_init,
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

  -- Terraform
  lsp.terraformls.setup { on_attach = M.on_attach, on_init = M.on_init, capabilities = M.capabilities }
  lsp.tflint.setup { on_attach = M.on_attach, on_init = M.on_init, capabilities = M.capabilities }

  -- Python (Poetry env)
  local poetry_env_ok, poetry_env_path = pcall(function()
    local p = vim.fn.systemlist("poetry env info -p")[1]
    return (p and #p > 0) and (p .. "/bin/python") or nil
  end)

  lsp.pyright.setup {
    on_attach = M.on_attach,
    on_init = M.on_init,
    capabilities = M.capabilities,
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
  lsp.vtsls.setup {
    on_attach = M.on_attach,
    -- on_init = M.on_init,
    capabilities = M.capabilities,
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

  -- Tailwind CSS
  lsp.tailwindcss.setup { on_attach = M.on_attach, on_init = M.on_init, capabilities = M.capabilities }

  -- Emmet (React JSX/TSX snippets)
  lsp.emmet_ls.setup {
    on_attach = M.on_attach,
    on_init = M.on_init,
    capabilities = M.capabilities,
    filetypes = { "html", "css", "javascriptreact", "typescriptreact", "less", "sass", "scss" },
  }

  -- CSS / HTML
  lsp.cssls.setup { on_attach = M.on_attach, on_init = M.on_init, capabilities = M.capabilities }
  lsp.html.setup { on_attach = M.on_attach, on_init = M.on_init, capabilities = M.capabilities }

  -- JSON
  local ok_schemastore, schemastore = pcall(require, "schemastore")
  lsp.jsonls.setup {
    on_attach = M.on_attach,
    on_init = M.on_init,
    capabilities = M.capabilities,
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
  lsp.eslint.setup {
    on_attach = function(client, bufnr)
      M.on_attach(client, bufnr)
      -- Uncomment to auto-fix on save:
      -- vim.api.nvim_create_autocmd("BufWritePre", { buffer = bufnr, command = "EslintFixAll" })
    end,
    on_init = M.on_init,
    capabilities = M.capabilities,
  }
end

return M
