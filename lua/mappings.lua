local map = vim.keymap.set

-- nvimtree
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-- fff.nvim (file find + grep)
map("n", "<leader>ff", function() require("fff").find_files() end, { desc = "find files" })
map("n", "<leader>fw", function() require("fff").live_grep() end, { desc = "live grep" })
map("n", "<leader>fz", function() require("fff").live_grep({ grep = { modes = { "fuzzy", "plain" } } }) end, { desc = "fuzzy grep" })
map("n", "<leader>fc", function() require("fff").live_grep({ query = vim.fn.expand("<cword>") }) end, { desc = "grep current word" })

-- fzf-lua (git + oldfiles)
map("n", "<leader>fo", "<cmd>FzfLua oldfiles<CR>", { desc = "old files" })
map("n", "<leader>gt", "<cmd>FzfLua git_status<CR>", { desc = "git status" })
map("n", "<leader>cm", "<cmd>FzfLua git_commits<CR>", { desc = "git commits" })

-- tabufline
map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })

map("n", "<tab>", function()
  require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })

map("n", "<S-tab>", function()
  require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

map("n", "<leader>x", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "buffer close" })

-- Comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- diagnostics
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- Use Esc to turn off search highlighting
map("n", "<Esc>", "<cmd> :noh <CR>")

-- Diagnostics
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostics" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
