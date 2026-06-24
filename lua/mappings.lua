local map = vim.keymap.set

-- nvimtree
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-- fzf-lua (git + oldfiles)
map("n", "<leader>fo", "<cmd>FzfLua oldfiles<CR>", { desc = "old files" })
map("n", "<leader>gt", "<cmd>FzfLua git_status<CR>", { desc = "git status" })
map("n", "<leader>cm", "<cmd>FzfLua git_commits<CR>", { desc = "git commits" })

-- tabufline
map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })

map("n", "<S-l>", function()
  require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })

map("n", "<S-h>", function()
  require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

-- Tab / S-Tab also cycle buffers (preferred over freeing <C-i>/jumplist)
map("n", "<Tab>", function()
  require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })

map("n", "<S-Tab>", function()
  require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

map("n", "<leader>x", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "buffer close" })

-- Comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- general
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "save file" })
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "clear search highlight" })

-- diagnostics
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev diagnostic" })
