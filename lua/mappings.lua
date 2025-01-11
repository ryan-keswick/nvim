local map = vim.keymap.set

-- nvimtree
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })

-- telescope
map("n", "<leader>ff", "<cmd> Telescope find_files <CR>")
map("n", "<leader>fo", "<cmd> Telescope oldfiles <CR>")
map("n", "<leader>fw", "<cmd> Telescope live_grep <CR>")
map("n", "<leader>gt", "<cmd> Telescope git_status <CR>")
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
