local o = vim.o
local opt = vim.opt
local g = vim.g
local api = vim.api

o.laststatus = 3
o.showmode = false

g.mapleader = " "

-- Share the clipboard with the system
o.clipboard = "unnamedplus"
o.cursorline = true
o.cursorlineopt = "number"

-- Indenting
o.expandtab = true   -- Use spaces instead of tabs
o.shiftwidth = 2     -- Number of spaces for each indent level
o.smartindent = true -- Automatically indent based on context
o.tabstop = 2        -- Number of spaces a tab character displays as
o.softtabstop = 2    -- Number of spaces inserted/deleted with Tab/Backspace

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

-- interval for writing swap file to disk, also used by gitsigns
o.updatetime = 250

-- bufferline.nvim
o.termguicolors = true

-- Commentstring
api.nvim_create_autocmd("FileType", {
  pattern = "terraform",
  callback = function()
    opt.commentstring = "# %s"
  end,
})

-- avante.nvim
-- views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3
