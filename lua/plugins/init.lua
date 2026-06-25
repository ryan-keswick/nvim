return {
  "nvim-lua/plenary.nvim",

  {
    "nvchad/ui",
    lazy = false,
    config = function()
      require "nvchad"
    end
  },

  {
    "nvchad/base46",
    lazy = false,
    build = function()
      require("base46").load_all_highlights()
    end,
  },


  "nvzone/volt",
  "nvzone/menu",
  {
    "nvzone/minty",
    cmd = { "Huefy", "Shades" }
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
      { "<c-h>",  "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>",  "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>",  "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>",  "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },

  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = require "plugins.configs.nvimtree"
  },

  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    config = function()
      local devicons = require("nvim-web-devicons")
      -- Reuse devicons' real json glyph (the audit shipped empty icon strings).
      local json_glyph = (devicons.get_icons().json or {}).icon or ""
      devicons.set_icon({
        jsonnet   = { icon = json_glyph, color = "#0095d8", cterm_color = "74", name = "Jsonnet" },
        libsonnet = { icon = json_glyph, color = "#7a5cff", cterm_color = "99", name = "Libsonnet" },
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- pin: config uses the master-branch API; main is the rewrite
    build = ":TSUpdate", -- keep parsers in sync when nvim auto-upgrades
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    config = function()
      require "plugins.configs.treesitter"
    end,
  },

  -- we use cmp plugin only when in insert mode
  -- so lets lazyload it at InsertEnter event, to know all the events check h-events
  -- completion , now all of these plugins are dependent on cmp, we load them after cmp
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      -- cmp sources
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lua",

      --list of default snippets
      "rafamadriz/friendly-snippets",

      -- snippets engine
      {
        "L3MON4D3/LuaSnip",
        freeze = true,
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
    },
    config = function()
      local cmp = require "cmp"
      local opts = require "plugins.configs.cmp"
      cmp.setup(opts)

      local ok_ap, ap = pcall(require, "nvim-autopairs.completion.cmp")
      if ok_ap then
        cmp.event:on("confirm_done", ap.on_confirm_done())
      end
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
      require "plugins.configs.lspconfig".defaults()
    end,
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    opts = function()
      return require("plugins.configs.conform")
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
        map("n", "]c", function() gs.nav_hunk("next") end, "gitsigns: next hunk")
        map("n", "[c", function() gs.nav_hunk("prev") end, "gitsigns: prev hunk")

        -- Actions
        map("n", "<leader>hs", gs.stage_hunk, "gitsigns: stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "gitsigns: reset hunk")
        map("n", "<leader>hp", gs.preview_hunk, "gitsigns: preview hunk")
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "gitsigns: blame line")
        map("n", "<leader>tb", gs.toggle_current_line_blame, "gitsigns: toggle line blame")
      end,
    },
  },


  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local threads = tostring(vim.uv.available_parallelism())
      require("fzf-lua").setup({
        "default-title",
        fzf_bin = "fzf",
        files = {
          cmd = "fd --type f --no-follow --threads " .. threads .. " --exclude bazel-* --exclude node_modules",
        },
        grep = {
          cmd = "rg --color=never --no-heading --with-filename --line-number --column --smart-case --threads=" .. threads .. " --no-follow --glob=!bazel-* --glob=!node_modules",
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
      })
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
      { "<leader>ff", function() require("fff").find_files() end, desc = "find files" },
      { "<leader>fw", function() require("fff").live_grep() end, desc = "live grep" },
      { "<leader>fz", function() require("fff").live_grep({ grep = { modes = { "fuzzy", "plain" } } }) end, desc = "fuzzy grep" },
      { "<leader>fc", function() require("fff").live_grep({ query = vim.fn.expand("<cword>") }) end, desc = "grep current word" },
    },
    opts = {
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
    lazy = true
  },

  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },

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
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },

  { "echasnovski/mini.surround", event = "VeryLazy", opts = {} },
}
