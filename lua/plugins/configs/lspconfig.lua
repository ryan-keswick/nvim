-- Single source of truth for enabled LSP servers. The list feeds
-- vim.lsp.enable() in M.defaults(); mason-lspconfig installs all entries
-- except the exact-version tools filtered below.
-- mason-lspconfig v2 defaults automatic_enable to true, which would enable
-- every installed server behind our back; it is turned off below so removing
-- a name here actually disables the server.
local servers = {
  -- core
  "eslint",
  "html",
  "jsonls",
  "yamlls",
  "dockerls",
  "lua_ls",
  "basedpyright",
  "ruff",
  "terraformls",
  "bashls",
  "tflint",
  "gopls",
  "jsonnet_ls",
  "starpls",
  "helm_ls",

  -- React stack
  "vtsls",
  "tailwindcss",
  "emmet_ls",
  "cssls",
}

-- Ruff and TFLint are also installed in the shell from the same pinned Nix
-- revision. Let mason-tool-installer reconcile their exact versions instead
-- of racing mason-lspconfig's latest-version install on a fresh devbox.
local mason_servers = vim.tbl_filter(function(server)
  return server ~= "ruff" and server ~= "tflint"
end, servers)

require("mason").setup()
require("mason-lspconfig").setup {
  ensure_installed = mason_servers,
  automatic_enable = false,
}

-- Non-LSP formatters and exact editor/shell tool versions managed by Mason.
require("mason-tool-installer").setup {
  ensure_installed = {
    { "ruff", version = "0.15.20" },
    { "tflint", version = "v0.61.0" },
    "goimports",
    "gofumpt",
    "stylua",
  },
  run_on_start = true,
}

local workspace = require "workspace"

-- The canva monorepo is the ~/work repo that ships tools/dprint/dprint.
local canva_workspace = workspace.find_work_repo "tools/dprint/dprint"

-- In Terraform a module is a single directory. The default root_markers
-- ('.terraform', '.git') resolve to the monorepo root, which makes terraform-ls
-- and tflint try to index every .tf file in ~/work/infrastructure (15k+ files)
-- and freezes the editor on open. Pin the root to the file's own directory so
-- each server only indexes the one module being edited.
local function tf_module_root(bufnr, on_dir)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  on_dir(vim.fs.dirname(fname))
end

-- A stray ~/.git directory is enough for the default Python root markers to
-- treat the whole home directory as a workspace and recursively scan every
-- checkout under ~/work. Preserve each server's marker priority, but only start
-- for a marked root outside HOME; markerless buffers are skipped instead of
-- letting a rootless server inherit Neovim's broad working directory.
local function python_root_dir(root_markers)
  local home = vim.fs.normalize(assert(vim.env.HOME))
  local markers = vim.deepcopy(assert(root_markers))

  return function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, markers)
    if not root or vim.fs.normalize(root) == home then
      return
    end
    on_dir(root)
  end
end

local M = {}
local map = vim.keymap.set

local function augroup(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

-- on_attach: keymaps
M.on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
  map("n", "gd", "<cmd>FzfLua lsp_definitions<CR>", opts "Go to definition")
  map("n", "gi", vim.lsp.buf.implementation, opts "Go to implementation")
  map("n", "<leader>sh", vim.lsp.buf.signature_help, opts "Show signature help")
  map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
  map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")
  map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts "List workspace folders")
  map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Go to type definition")
  map("n", "<leader>rn", vim.lsp.buf.rename, opts "Rename")
  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts "Code action")
  map("n", "gr", "<cmd>FzfLua lsp_references<CR>", opts "Show references")
  map("n", "<leader>th", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end, opts "Toggle inlay hints")
end

-- Keep Blink lazy while advertising its completion capabilities to LSP servers.
M.capabilities = vim.lsp.protocol.make_client_capabilities()
local completion_capabilities = M.capabilities.textDocument.completion
completion_capabilities.completionItem.resolveSupport.properties = {
  "documentation",
  "detail",
  "additionalTextEdits",
  "command",
  "data",
}
completion_capabilities.completionItem.insertTextModeSupport = { valueSet = { 1 } }
completion_capabilities.completionItem.labelDetailsSupport = true
completion_capabilities.completionList.itemDefaults = {
  "commitCharacters",
  "editRange",
  "insertTextFormat",
  "insertTextMode",
  "data",
}
completion_capabilities.insertTextMode = 1

-- defaults
M.defaults = function()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = augroup "LspAttachKeymaps",
    callback = function(args)
      -- LspAttach fires once per attaching client (4x in a .tsx buffer);
      -- only set the buffer keymaps the first time.
      if vim.b[args.buf].lsp_keymaps_set then
        return
      end
      vim.b[args.buf].lsp_keymaps_set = true
      M.on_attach(nil, args.buf)
    end,
  })

  -- terraform-ls' semanticTokens/full is very expensive in the
  -- infrastructure monorepo: every edit/scroll fires a request, and while
  -- the server is busy preloading provider schemas the requests queue up
  -- and stall the UI. Drop the capability — treesitter still highlights.
  vim.api.nvim_create_autocmd("LspAttach", {
    group = augroup "TerraformlsSemanticTokens",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "terraformls" then
        client.server_capabilities.semanticTokensProvider = nil
      end
    end,
  })

  -- Per-module roots spawn one terraformls/tflint per module dir, and
  -- terraformls preloads provider schemas (hundreds of MB) without ever
  -- exiting on its own — long tmux sessions accumulate idle servers. Stop a
  -- client 30s after its last buffer detaches. attached_buffers is checked
  -- inside the deferred fn because LspDetach fires before detach completes.
  vim.api.nvim_create_autocmd("LspDetach", {
    group = augroup "TerraformServerReap",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client or (client.name ~= "terraformls" and client.name ~= "tflint") then
        return
      end
      local id = args.data.client_id
      vim.defer_fn(function()
        local c = vim.lsp.get_client_by_id(id)
        if c and not c:is_stopped() and next(c.attached_buffers) == nil then
          c:stop()
        end
      end, 30000)
    end,
  })

  -- Merge defaults so existing shared LSP settings stay intact.
  vim.lsp.config("*", {
    capabilities = M.capabilities,
  })

  -- Diagnostics (0.12 ships with virtual_text off by default)
  vim.diagnostic.config {
    virtual_text = { source = "if_many", spacing = 2 },
    severity_sort = true,
    float = { source = true, border = "rounded" },
  }

  -- Diagnostics list pickers (via fzf-lua)
  map("n", "<leader>fd", "<cmd>FzfLua diagnostics_document<CR>", { desc = "LSP document diagnostics" })
  map("n", "<leader>fD", "<cmd>FzfLua diagnostics_workspace<CR>", { desc = "LSP workspace diagnostics" })

  -- Lua
  vim.lsp.config.lua_ls = {
    on_init = function(client)
      -- Tree-sitter already handles semantic highlighting. Document-color
      -- previews are not worth the tens-of-seconds LuaLS recomputation that
      -- blocked more useful requests in this config.
      client.server_capabilities.colorProvider = nil
      client.server_capabilities.semanticTokensProvider = nil
    end,
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          path = { "lua/?.lua", "lua/?/init.lua" },
        },
        diagnostics = {
          globals = { "vim" },
          libraryFiles = "Disable",
          workspaceEvent = "None",
        },
        workspace = {
          checkThirdParty = "Disable",
          library = { vim.env.VIMRUNTIME },
        },
      },
    },
  }

  -- Last-resort interpreter for roots without a .venv: the canva monorepo
  -- venv when checked out, else whatever python3 is on PATH.
  local fallback_venv = canva_workspace and (canva_workspace .. "/.venv/bin/python") or ""
  local fallback_python = vim.fn.filereadable(fallback_venv) == 1 and fallback_venv or vim.fn.exepath "python3"
  local basedpyright_root_dir = python_root_dir(vim.lsp.config.basedpyright.root_markers)
  local ruff_root_dir = python_root_dir(vim.lsp.config.ruff.root_markers)

  vim.lsp.config.basedpyright = {
    root_dir = basedpyright_root_dir,
    workspace_required = true,
    -- node defaults to a ~4GB old-space heap; indexing the canva monorepo blows
    -- past it and the langserver dies with "JavaScript heap out of memory"
    -- (exit 250). Raise the limit - the box has plenty of RAM.
    cmd_env = { NODE_OPTIONS = "--max-old-space-size=12288" },
    -- Resolve interpreter/search paths per root instead of pinning the canva
    -- venv + monorepo into every python buffer. The server reads the
    -- interpreter from settings.python.pythonPath, not settings.basedpyright.
    before_init = function(_, config)
      config.settings = config.settings or {}
      config.settings.python = config.settings.python or {}
      local venv_owner = config.root_dir and vim.fs.root(config.root_dir, ".venv")
      if venv_owner then
        config.settings.python.pythonPath = venv_owner .. "/.venv/bin/python"
      elseif fallback_python ~= "" then
        config.settings.python.pythonPath = fallback_python
      end
      if canva_workspace and config.root_dir == canva_workspace then
        local bp = config.settings.basedpyright or {}
        config.settings.basedpyright = bp
        bp.analysis = bp.analysis or {}
        bp.analysis.extraPaths = { canva_workspace }
      end
    end,
    settings = {
      basedpyright = {
        analysis = {
          typeCheckingMode = "basic",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "openFilesOnly",
          logLevel = "Information",
          fileEnumerationTimeout = 300,
          inlayHints = {
            variableTypes = false,
            callArgumentNames = false,
          },
        },
      },
    },
  }

  -- Ruff (lint + code actions to match CI; formatting stays dprint, and
  -- hover stays with basedpyright)
  vim.lsp.config("ruff", {
    cmd = { "ruff", "server", "--quiet" },
    root_dir = ruff_root_dir,
    workspace_required = true,
    on_attach = function(client)
      client.server_capabilities.hoverProvider = false
    end,
  })

  -- React / TS core (VTSLS only)
  vim.lsp.config.vtsls = {
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
      },
    },
  }

  -- YAML
  vim.lsp.config.yamlls = {
    settings = {
      yaml = {
        schemaStore = { enable = false, url = "" },
        schemas = vim.tbl_extend(
          "force",
          ok_schemastore and schemastore.yaml.schemas() or {},
          { kubernetes = { "manifests/**/*.yaml", "*.k8s.yaml" } }
        ),
        validate = true,
        keyOrdering = false,
      },
    },
  }

  -- ESLint: fix on save. nvim-lspconfig's lsp/eslint.lua creates the
  -- :LspEslintFixAll command inside its own on_attach, so chain it via the
  -- call form (which merges) — the assignment form would replace the base
  -- on_attach and the command would never exist.
  local base_eslint_on_attach = vim.lsp.config.eslint.on_attach
  vim.lsp.config("eslint", {
    on_attach = function(client, bufnr)
      if base_eslint_on_attach then
        base_eslint_on_attach(client, bufnr)
      end
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup("EslintFixAll_" .. bufnr),
        buffer = bufnr,
        command = "LspEslintFixAll",
      })
    end,
  })

  -- Terraform (include Terragrunt .hcl files)
  local base_terraformls_on_attach = vim.lsp.config.terraformls.on_attach
  vim.lsp.config.terraformls = {
    cmd = { "terraform-ls", "serve", "-log-file", "/dev/null" },
    filetypes = { "terraform", "terraform-vars", "hcl" },
    root_dir = tf_module_root,
    on_attach = function(client, bufnr)
      -- nvim-lspconfig's current callback uses the newer enable() API. Keep
      -- that callback on newer Neovim builds and emulate it on this pinned
      -- build, which only exposes refresh().
      if vim.lsp.codelens.enable then
        if base_terraformls_on_attach then
          base_terraformls_on_attach(client, bufnr)
        end
        return
      end

      local refresh = function()
        vim.lsp.codelens.refresh { bufnr = bufnr }
      end
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
        group = augroup("TerraformCodeLens_" .. bufnr),
        buffer = bufnr,
        callback = refresh,
      })
      vim.schedule(refresh)
    end,
  }

  -- Go (disable gopackagesdriver — bazel workspace causes issues with default driver)
  vim.lsp.config.gopls = {
    filetypes = { "go", "gomod", "gosum", "gowork", "gotmpl" },
    cmd_env = { GOPACKAGESDRIVER = "off" },
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
        },
        staticcheck = true,
        gofumpt = true,
        -- gopls sends no inlay hints unless asked, which made the
        -- <leader>th toggle a no-op in Go buffers
        hints = {
          parameterNames = true,
          assignVariableTypes = true,
          compositeLiteralFields = true,
          constantValues = true,
          rangeVariableTypes = true,
        },
      },
    },
  }

  -- Bash (prefer workspace-pinned shellcheck if present)
  vim.lsp.config.bashls = {
    settings = {
      bashIde = {
        shellcheckPath = workspace.find_work_tool "tools/dotslash/bin/shellcheck",
      },
    },
  }

  -- Tailwind CSS
  vim.lsp.config.tailwindcss = {
    filetypes = {
      "html",
      "css",
      "scss",
      "less",
      "postcss",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "vue",
      "svelte",
      "templ",
    },
    root_dir = function(bufnr, on_dir)
      local fname = vim.api.nvim_buf_get_name(bufnr)
      local root = vim.fs.find({
        "tailwind.config.js",
        "tailwind.config.cjs",
        "tailwind.config.mjs",
        "tailwind.config.ts",
        "postcss.config.js",
        "postcss.config.cjs",
        "postcss.config.mjs",
        "postcss.config.ts",
      }, { path = fname, upward = true })[1]
      on_dir(root and vim.fs.dirname(root) or nil)
    end,
  }

  -- Jsonnet
  -- The grafana jsonnet-language-server only serves go-to-definition and
  -- completion when the file currently evaluates without error. In the k8s
  -- monorepo, imports like "manifests/src/..." and "third_party/..." are
  -- resolved relative to the repo root (matching the go-jsonnet renderer's
  -- FileImporter{JPaths:[root]}). Pin the repo root onto the search path with
  -- -J so those imports resolve and whole-file eval succeeds; otherwise a
  -- single unresolved import silently kills all language features.
  vim.lsp.config.jsonnet_ls = {
    cmd = function(dispatchers, config)
      local root = config.root_dir or vim.fn.getcwd()
      return vim.lsp.rpc.start({ "jsonnet-language-server", "-l", "fatal", "-J", root }, dispatchers)
    end,
  }

  -- Starlark / Bazel (BUILD, .bzl, .star, WORKSPACE)
  -- starpls shells out to `bazel info`, which requires CWD to be inside a
  -- Bazel workspace. Launch starpls with cmd_cwd = root_dir so `bazel info`
  -- works regardless of where nvim was started from.
  vim.lsp.config.starpls = {
    filetypes = { "bzl", "starlark" },
    cmd = function(dispatchers, config)
      return vim.lsp.rpc.start({ "starpls", "server" }, dispatchers, {
        cwd = config.root_dir or vim.fn.getcwd(),
      })
    end,
  }

  -- TFLint (Terraform linter)
  vim.lsp.config.tflint = {
    -- The langserver writes every JSON-RPC payload, including complete source
    -- buffers, to stderr with no usable log-level switch. Neovim records all
    -- server stderr as errors, so discard this verbose stream only; process
    -- exits and diagnostics still travel through the LSP transport.
    cmd = { "sh", "-c", "exec tflint --langserver 2>/dev/null" },
    root_dir = tf_module_root,
  }

  -- Enable all configured LSP servers
  vim.lsp.enable(servers)
end

return M
