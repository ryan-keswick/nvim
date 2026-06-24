require("nvim-treesitter.configs").setup {
  ensure_installed = {
    "bash",
    "comment",
    "css",
    "csv",
    "diff",
    "dockerfile",
    "gitcommit",
    "gitignore",
    "go",
    "hcl",
    "html",
    "javascript",
    "json",
    "jsonnet",
    "lua",
    "luadoc",
    "make",
    "markdown",
    "markdown_inline",
    "python",
    "query",
    "regex",
    "starlark",
    "terraform",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
  },

  auto_install = true,

  highlight = {
    enable = true,
    use_languagetree = true,
    disable = function(_, buf)
      local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
      return ok and stats and stats.size > 256 * 1024
    end,
  },

  indent = { enable = true },
}
