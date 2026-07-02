-- nvim-treesitter main-branch API: require("nvim-treesitter.configs") is gone.
-- install() only downloads/compiles parsers (async, skips already-installed);
-- highlight and indent are enabled per buffer by the FileType autocmd below.
require("nvim-treesitter").install {
  "bash",
  "css",
  "csv",
  "diff",
  "dockerfile",
  "gitcommit",
  "gitignore",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "hcl",
  "helm",
  "html",
  "java",
  "javascript",
  "json",
  "jsonnet",
  "lua",
  "luadoc",
  "make",
  "markdown",
  "markdown_inline",
  "proto",
  "python",
  "query",
  "regex",
  "rego",
  "starlark",
  "terraform",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

-- Treesitter indent is notoriously wrong for these; keep the builtin indent.
local no_ts_indent = { python = true, yaml = true }

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match) or args.match

    -- Big-file guard (same 256KB cutoff the old highlight.disable used).
    local max = vim.g.bigfile_size or 256 * 1024
    local ok_stat, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok_stat and stats and stats.size > max then
      return
    end

    -- language.add returns true on success, nil (or throws) when no parser.
    local ok_add, added = pcall(vim.treesitter.language.add, lang)
    if ok_add and added then
      vim.treesitter.start(args.buf)
      if not no_ts_indent[lang] then
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end
  end,
})
