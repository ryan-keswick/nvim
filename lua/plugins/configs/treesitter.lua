require("nvim-treesitter.configs").setup {
  ensure_installed = {
    "bash",
    "css",
    "csv",
    "comment",
    "dockerfile",
    "gitignore",
    "html",
    "javascript",
    "lua",
    "python",
    "terraform",
    "typescript",
    "vim",
    "vimdoc",
  },

  highlight = {
    enable = true,
    use_languagetree = true,
  },

  indent = { enable = true }
}
