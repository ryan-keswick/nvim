vim.loader.enable()

require "options"
require "mappings"

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

-- Checks if lazy.nvim is installed, if not installs
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- Adding lazy path to Neovims runtime path
vim.opt.rtp:prepend(lazypath)

-- Loads list of plugins
local plugins = require "plugins"

-- put this in your main init.lua file ( before lazy setup )
-- Setting up a cache directory path for the "base46" theming system
vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46_cache/"

-- Sets up plugins
require("lazy").setup(plugins, require "lazy_config")

-- Load base46 highlight cache; regenerate it if missing (fresh install) or
-- predating the newest chadrc integration (grug_far as the freshness probe).
if vim.uv.fs_stat(vim.g.base46_cache) and vim.uv.fs_stat(vim.g.base46_cache .. "grug_far") then
  for _, v in ipairs(vim.fn.readdir(vim.g.base46_cache)) do
    dofile(vim.g.base46_cache .. v)
  end
else
  require("base46").load_all_highlights()
end
