require "options"
require "mappings"
--require "commands"

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
end

vim.opt.rtp:prepend(lazypath)

local plugins = require "plugins"

-- put this in your main init.lua file ( before lazy setup )
vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46_cache/"

require("lazy").setup(plugins, require "lazy_config")

for _, v in ipairs(vim.fn.readdir(vim.g.base46_cache)) do
  dofile(vim.g.base46_cache .. v)
end
