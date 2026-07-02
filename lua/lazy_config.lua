return {
  rocks = { enabled = false },

  -- Lazy-load plugins by default. Individual specs opt in to eager loading
  -- with `lazy = false` (e.g. the NvChad UI/theme plugins).
  defaults = { lazy = true },

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
}
