local o = vim.o
local opt = vim.opt
local g = vim.g
local api = vim.api

o.laststatus = 3
o.showmode = false

g.mapleader = " "
g.maplocalleader = " "

-- Disable unused language providers (this is a pure-Lua config).
g.loaded_python3_provider = 0
g.loaded_ruby_provider = 0
g.loaded_perl_provider = 0
g.loaded_node_provider = 0

-- Share the clipboard with the system.
-- Headless remote box: no clipboard provider, so use an OSC 52 provider that
-- pipes the + / * registers over the terminal escape sequence to the local machine.
-- Paste stays local: OSC 52 paste round-trips the terminal on every p and can
-- stall 1s+ outside tmux ("Waiting for OSC 52 response"), so read the unnamed
-- register instead.
local function paste()
  return { vim.split(vim.fn.getreg '"', "\n"), vim.fn.getregtype '"' }
end
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy "+",
    ["*"] = require("vim.ui.clipboard.osc52").copy "*",
  },
  paste = {
    ["+"] = paste,
    ["*"] = paste,
  },
}
o.clipboard = "unnamedplus"
o.cursorline = true

-- Indenting
o.expandtab = true -- Use spaces instead of tabs
o.shiftwidth = 2 -- Number of spaces for each indent level
o.smartindent = true -- Automatically indent based on context
o.tabstop = 2 -- Number of spaces a tab character displays as
o.softtabstop = 2 -- Number of spaces inserted/deleted with Tab/Backspace

-- Set this before the colorscheme
vim.opt.fillchars = { eob = " " } -- Use a space character to fill empty lines at the end of a buffer
o.ignorecase = true
o.smartcase = true
o.mouse = "a"

-- Numbers
o.number = true
o.relativenumber = true
o.numberwidth = 2
o.ruler = false

-- Vertical Ruler
o.colorcolumn = "80,120"
o.cursorlineopt = "both" -- to enable cursorline!

-- disable nvim intro
opt.shortmess:append "sI"

o.signcolumn = "yes"
o.splitbelow = true
o.splitright = true
o.timeoutlen = 400
o.undofile = true
o.swapfile = false -- undofile covers recovery; swapfiles just leave E325 prompts after unclean stops

-- interval for writing swap file to disk, also used by gitsigns
o.updatetime = 250

-- 24-bit colour in the terminal
o.termguicolors = true

-- Core option wins
o.scrolloff = 8 -- keep 8 lines of context around the cursor
o.splitkeep = "screen" -- keep text on screen stable when splitting
opt.diffopt:append "linematch:60" -- finer line matching in diffs
vim.o.winborder = "rounded" -- 0.12 — rounded borders on all floating windows (LSP floats)

-- Treesitter folding (lazy-evaluated, so safe even with no parser for a buffer)
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevelstart = 99 -- folds open by default
o.foldenable = true

-- Starlark (.star) has no bundled ftplugin, so commentstring is empty and gcc
-- no-ops. Set it explicitly. (tf/bzl/jsonnet/hcl get theirs from bundled ftplugins.)
api.nvim_create_autocmd("FileType", {
  group = api.nvim_create_augroup("UserCommentstring", { clear = true }),
  pattern = "starlark",
  callback = function()
    vim.bo.commentstring = "# %s"
  end,
})

-- Big-file guard: skip expensive expr folding/indenting for large files.
-- (lua/plugins/ reads vim.g.bigfile_size too, to disable treesitter highlight.)
g.bigfile_size = 256 * 1024
api.nvim_create_autocmd("BufReadPre", {
  group = api.nvim_create_augroup("UserBigFile", { clear = true }),
  callback = function(args)
    local stat = vim.uv.fs_stat(args.match)
    if stat and stat.size > g.bigfile_size then
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.foldexpr = ""
      vim.opt_local.indentexpr = ""
    end
  end,
})

-- Auto-reload files changed outside nvim (other tmux panes, git, agents).
-- 0.12 ships no default checktime autocmd.
local autoread = api.nvim_create_augroup("UserAutoRead", { clear = true })
api.nvim_create_autocmd({ "FocusGained", "BufEnter", "TermLeave" }, {
  group = autoread,
  callback = function()
    if vim.bo.buftype == "" and vim.bo.modifiable then
      vim.cmd "checktime"
    end
  end,
})
api.nvim_create_autocmd("FileChangedShellPost", {
  group = autoread,
  callback = function(args)
    vim.notify("File changed on disk, buffer reloaded: " .. args.file, vim.log.levels.WARN)
  end,
})

-- Mustache templates with a double extension (foo.tf.mustache, foo.py.mustache)
-- get the underlying file's filetype so its LSP, treesitter, and tooling attach.
-- Bare .mustache (no inner extension) is left as the default mustache filetype.
-- The {{ }} tags will show as syntax errors in the underlying LSP — accepted
-- trade-off for completion/navigation on the template body.
vim.filetype.add {
  pattern = {
    [".*%.mustache"] = function(path)
      local inner = path:gsub("%.mustache$", ""):match "%.([%w]+)$"
      local map = {
        tf = "terraform",
        tfvars = "terraform-vars",
        py = "python",
        java = "java",
        yaml = "yaml",
        yml = "yaml",
        json = "json",
        sql = "sql",
        ddl = "sql",
        bazel = "bzl",
        bzl = "bzl",
      }
      return inner and map[inner] or nil
    end,
  },
}
