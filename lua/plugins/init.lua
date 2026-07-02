return {
  "nvim-lua/plenary.nvim",

  {
    "nvchad/ui",
    lazy = false,
    config = function()
      require "nvchad"
    end,
  },

  {
    "nvchad/base46",
    -- lazy: startup highlights come from the compiled cache (init.lua dofiles
    -- base46_cache); the module itself is only required on theme switch.
    build = function()
      require("base46").load_all_highlights()
    end,
  },

  "nvzone/volt",
  {
    "nvzone/minty",
    cmd = { "Huefy", "Shades" },
  },

  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },

  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = function()
      return require "plugins.configs.nvimtree"
    end,
  },

  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    config = function()
      local devicons = require "nvim-web-devicons"
      -- Reuse devicons' real json glyph (the audit shipped empty icon strings).
      local json_glyph = (devicons.get_icons().json or {}).icon or ""
      devicons.set_icon {
        jsonnet = { icon = json_glyph, color = "#0095d8", cterm_color = "74", name = "Jsonnet" },
        libsonnet = { icon = json_glyph, color = "#7a5cff", cterm_color = "99", name = "Libsonnet" },
      }
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- master is frozen; main is the maintained rewrite
    lazy = false, -- main README: lazy-loading is unsupported
    build = ":TSUpdate", -- keep parsers in sync when nvim auto-upgrades
    config = function()
      require "plugins.configs.treesitter"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main", -- must match the nvim-treesitter branch
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup {
        select = { lookahead = true },
      }

      local function sel(query)
        return function()
          require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
        end
      end

      local map = vim.keymap.set
      map({ "x", "o" }, "af", sel "@function.outer", { desc = "function outer" })
      map({ "x", "o" }, "if", sel "@function.inner", { desc = "function inner" })
      map({ "x", "o" }, "aa", sel "@parameter.outer", { desc = "parameter outer" })
      map({ "x", "o" }, "ia", sel "@parameter.inner", { desc = "parameter inner" })
      -- ak/ik, not ab/ib: ab/ib are the builtin a(/i( paren textobjects
      map({ "x", "o" }, "ak", sel "@block.outer", { desc = "block outer (hcl resource)" })
      map({ "x", "o" }, "ik", sel "@block.inner", { desc = "block inner" })

      -- ]c/[c (gitsigns), ]d/[d (diagnostics), ]x/[x (git-conflict) are taken
      map("n", "]f", function()
        require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
      end, { desc = "next function start" })
      map("n", "[f", function()
        require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
      end, { desc = "prev function start" })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = { max_lines = 4, multiline_threshold = 1 },
  },

  {
    "saghen/blink.cmp",
    version = "1.*", -- release tags ship the prebuilt fuzzy-matcher binary
    event = "InsertEnter",
    dependencies = {
      -- snippets engine
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
        dependencies = { "rafamadriz/friendly-snippets" },
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
    },
    opts = function()
      return require "plugins.configs.blink"
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      require("plugins.configs.lspconfig").defaults()
    end,
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>fm",
        function()
          require("conform").format { lsp_format = "fallback", timeout_ms = 10000 }
        end,
        mode = { "n", "v" },
        desc = "format buffer/range",
      },
    },
    opts = function()
      return require "plugins.configs.conform"
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("ibl").setup {
        indent = { char = "│" },
        scope = { char = "│", highlight = "Comment" },
      }
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(bufnr)
        local gs = require "gitsigns"

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Navigation
        map("n", "]c", function()
          gs.nav_hunk "next"
        end, "gitsigns: next hunk")
        map("n", "[c", function()
          gs.nav_hunk "prev"
        end, "gitsigns: prev hunk")

        -- Actions
        map("n", "<leader>hs", gs.stage_hunk, "gitsigns: stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "gitsigns: reset hunk")
        map("n", "<leader>hp", gs.preview_hunk, "gitsigns: preview hunk")
        map("n", "<leader>hb", function()
          gs.blame_line { full = true }
        end, "gitsigns: blame line")
        map("n", "<leader>tb", gs.toggle_current_line_blame, "gitsigns: toggle line blame")
      end,
    },
  },

  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- NOTE: file/grep excludes must be maintained in BOTH the fzf-lua and fff
    -- configs (fzf-lua: fd/rg flags below; fff: its own indexer options).
    config = function()
      local threads = tostring(vim.uv.available_parallelism())
      require("fzf-lua").setup {
        "default-title",
        fzf_bin = "fzf",
        files = {
          cmd = "fd --type f --no-follow --threads " .. threads .. " --exclude bazel-* --exclude node_modules",
        },
        grep = {
          cmd = "rg --color=never --no-heading --with-filename --line-number --column --smart-case --threads="
            .. threads
            .. " --no-follow --glob=!bazel-* --glob=!node_modules",
        },
        oldfiles = {
          -- v:oldfiles is only a startup snapshot from shada and is never
          -- refreshed during a session, so in long-lived (tmux-resurrect)
          -- sessions recently used files are missing/stale. Prepend the
          -- current session's buffers sorted by last-used for live MRU order.
          include_current_session = true,
        },
        winopts = {
          height = 0.85,
          width = 0.80,
          border = "none",
          preview = { layout = "horizontal", horizontal = "right:50%", border = "none" },
        },
      }
    end,
  },

  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    -- treesitter must load first: this nvim ships no bundled parsers, so fff's
    -- preview (which sets filetype -> ftplugin -> vim.treesitter.start) errors
    -- if nvim-treesitter (and its parser/ dir) isn't on the runtimepath yet.
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      {
        "<leader>ff",
        function()
          require("fff").find_files()
        end,
        desc = "find files",
      },
      {
        "<leader>fw",
        function()
          require("fff").live_grep()
        end,
        desc = "live grep",
      },
      {
        "<leader>fz",
        function()
          require("fff").live_grep { grep = { modes = { "fuzzy", "plain" } } }
        end,
        desc = "fuzzy grep",
      },
      {
        "<leader>fc",
        function()
          require("fff").live_grep { query = vim.fn.expand "<cword>" }
        end,
        desc = "grep current word",
      },
    },
    opts = {
      -- keep the bazel cache (~/.cache/bazel, reached via bazel-* symlinks) out of the index
      enable_home_dir_scanning = false,
      follow_symlinks = false,
      max_threads = vim.uv.available_parallelism(),
      layout = {
        prompt_position = "top",
      },
    },
  },

  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewFocusFiles" },
  },

  {
    "b0o/schemastore.nvim",
    lazy = true,
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>h", group = "git hunks" },
        { "<leader>w", group = "lsp workspace" },
        { "<leader>t", group = "toggle" },
        { "<leader>g", group = "git" },
        { "<leader>c", group = "code/git" },
        { "<leader>q", group = "session" },
        { "<leader>s", group = "search/replace" },
        { "gs", group = "surround", mode = { "n", "x" } },
      },
    },
  },

  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

  { "folke/lazydev.nvim", ft = "lua", opts = {} },

  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
    },
  },

  {
    -- gs* prefix: the defaults (sa/sd/sf/...) collide with flash.nvim's s
    "echasnovski/mini.surround",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
      },
    },
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "restore session (cwd)",
      },
      {
        "<leader>ql",
        function()
          require("persistence").load { last = true }
        end,
        desc = "restore last session",
      },
    },
  },

  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open()
        end,
        mode = { "n", "x" },
        desc = "search and replace",
      },
      {
        "<leader>sw",
        function()
          require("grug-far").open { prefills = { search = vim.fn.expand "<cword>" } }
        end,
        desc = "search and replace current word",
      },
    },
    opts = {
      engines = {
        -- keep excludes in sync with fzf-lua/fff
        ripgrep = { extraArgs = "--glob=!bazel-* --glob=!node_modules" },
      },
    },
  },

  { "akinsho/git-conflict.nvim", event = "BufReadPost", opts = {} },

  -- helm filetype detection + syntax (helm_ls needs the filetype to attach)
  { "towolf/vim-helm", ft = "helm" },
}
