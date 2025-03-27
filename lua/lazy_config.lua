return {
  -- Enable or disable lazy-loading for plugins.
  -- Set to `true` to lazy-load plugins (recommended for performance).
  -- Set to `false` to load all plugins at startup.
  lazy = false,

  -- Plugin installation settings.
  install = {
    -- Default colorscheme to install and use.
    colorscheme = { "nightfox" },

    -- Optional: Specify additional plugin installation behaviors.
    -- Example: Automatically install missing plugins on startup.
    -- missing = true,
  },

  -- Optional: Performance optimizations.
  -- performance = {
  --   rtp = {
  --     -- Disable unused rtp plugins for faster startup.
  --     disabled_plugins = {
  --       "netrw",
  --       "netrwPlugin",
  --     },
  --   },
  -- },

  -- Optional: Debugging settings for troubleshooting.
  -- debug = false,
}
