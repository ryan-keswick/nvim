require("nvim-treesitter.configs").setup {
  ensure_installed = {
    "bash",
    "comment",
    "css",
    "csv",
    "dockerfile",
    "gitignore",
    "html",
    "javascript",
    "json",
    "lua",
    "python",
    "terraform",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
  },

  highlight = {
    enable = true,
    use_languagetree = true,
  },

  indent = { enable = true },
}
