require("nvim-treesitter.configs").setup {
  ensure_installed = {
    "bash",
    "comment",
    "css",
    "csv",
    "dockerfile",
    "gitignore",
    "go",
    "html",
    "javascript",
    "json",
    "jsonnet",
    "lua",
    "markdown",
    "markdown_inline",
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
