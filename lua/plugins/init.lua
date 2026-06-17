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

  { "nvim-tree/nvim-web-devicons", lazy = true },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- pin: config uses the master-branch API; main is the rewrite
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    config = function()
      require "plugins.configs.treesitter"
    end,
  },

  {
    "akinsho/bufferline.nvim",
    event = "BufReadPre",
    opts = require "plugins.configs.bufferline"
  },

  {
    "echasnovski/mini.statusline",
    config = function()
      require("mini.statusline").setup { set_vim_settings = false }
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
      }

      -- autopairs , autocompletes ()[] etc
      -- {
      --  "windwp/nvim-autopairs",
      --  config = function()
      --    require("nvim-autopairs").setup()

      --    local cmp_autopairs = require "nvim-autopairs.completion.cmp"
      --    local cmp = require "cmp"
      --    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      --  end,
      -- },
    },
    config = function()
      local cmp = require "cmp"
      local opts = require "plugins.configs.cmp"
      cmp.setup(opts)
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require "plugins.configs.lspconfig".defaults()
    end,
  },

  {
    "stevearc/conform.nvim",
    lazy = true,
    event = { "BufWritePre" },
    opts = require "plugins.configs.conform",
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
    opts = {},
  },


  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local threads = vim.trim(vim.fn.system("nproc"))
      require("fzf-lua").setup({
        "default-title",
        fzf_bin = "fzf",
        files = {
          cmd = "fd --type f --no-follow --threads " .. threads .. " --exclude bazel-* --exclude node_modules",
        },
        grep = {
          cmd = "rg --color=never --no-heading --with-filename --line-number --column --smart-case --threads=" .. threads .. " --no-follow --glob=!bazel-* --glob=!node_modules",
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
    event = "VeryLazy",
    opts = {
      layout = {
        prompt_position = "top",
      },
    },
  },

  { "sindrets/diffview.nvim" },

  {
    "b0o/schemastore.nvim",
    lazy = true
  }
}
