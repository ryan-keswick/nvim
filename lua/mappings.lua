local map = vim.keymap.set

-- nvimtree
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-- fzf-lua (git + oldfiles)
map("n", "<leader>fo", "<cmd>FzfLua oldfiles<CR>", { desc = "old files" })
map("n", "<leader>fb", "<cmd>FzfLua buffers<CR>", { desc = "find buffers" })
map("n", "<leader>fr", "<cmd>FzfLua resume<CR>", { desc = "resume last fzf-lua picker (not fff greps)" })
map("n", "<leader>fh", "<cmd>FzfLua helptags<CR>", { desc = "help tags" })
map("n", "<leader>fk", "<cmd>FzfLua keymaps<CR>", { desc = "keymaps" })
map("n", "<leader>gt", "<cmd>FzfLua git_status<CR>", { desc = "git status" })
map("n", "<leader>gb", "<cmd>FzfLua git_branches<CR>", { desc = "git branches" })
map("n", "<leader>cm", "<cmd>FzfLua git_commits<CR>", { desc = "git commits" })

-- diffview
map("n", "<leader>gm", "<cmd>DiffviewOpen<CR>", { desc = "git merge/diff view" })

-- tabufline
map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })

-- Tab / S-Tab cycle buffers (preferred over freeing <C-i>/jumplist)
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
-- insert-mode <C-s> stays on the 0.12 default (LSP signature help)
map({ "n", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "save file" })
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "clear search highlight" })
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "cheatsheet" })

-- terminal
map("t", "<C-x>", "<C-\\><C-n>", { desc = "escape terminal mode" })

map({ "n", "t" }, "<A-i>", function()
  require("nvchad.term").toggle { pos = "float", id = "fterm" }
end, { desc = "terminal toggle floating" })

map({ "n", "t" }, "<A-h>", function()
  require("nvchad.term").toggle { pos = "sp", id = "hterm" }
end, { desc = "terminal toggle horizontal" })

map({ "n", "t" }, "<A-v>", function()
  require("nvchad.term").toggle { pos = "vsp", id = "vterm" }
end, { desc = "terminal toggle vertical" })

-- diagnostics (]d/[d/]D/[D come from the 0.12 defaults, with count support)
map("n", "<leader>d", function()
  vim.diagnostic.open_float()
end, { desc = "Show diagnostic" })
