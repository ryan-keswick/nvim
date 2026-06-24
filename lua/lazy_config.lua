return {
  rocks = { enabled = false },

  -- Lazy-load plugins by default. Individual specs opt in to eager loading
  -- with `lazy = false` (e.g. the NvChad UI/theme plugins).
  defaults = { lazy = true },

  -- Plugin installation settings.
  install = {
    -- Default colorscheme to install and use.
    colorscheme = { "nightfox" },

    -- Optional: Specify additional plugin installation behaviors.
    -- Example: Automatically install missing plugins on startup.
    -- missing = true,
  },

  -- Performance optimizations: disable unused built-in rtp plugins for faster startup.
  performance = {
    rtp = {
      disabled_plugins = {
        "netrwPlugin",
        "gzip",
        "zipPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "rplugin",
        "spellfile",
      },
    },
  },

  -- Optional: Debugging settings for troubleshooting.
  -- debug = false,
}
