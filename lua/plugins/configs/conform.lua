-- Resolve tools only inside the buffer's own Git repository. Falling back to
-- the first matching tool under ~/work can run a Canva wrapper from k8s or
-- infrastructure, where its Git-root lookup resolves the wrong binary.
local function repo_tool(relpath)
  local fallback = vim.fs.basename(relpath)
  return function(_, ctx)
    local root = vim.fs.root(ctx.dirname, ".git")
    local candidate = root and vim.fs.joinpath(root, relpath)
    if candidate and vim.fn.executable(candidate) == 1 then
      return candidate
    end
    return fallback
  end
end

-- Format-on-save escape hatches (conform docs recipe):
--   :FormatDisable  — everywhere
--   :FormatDisable! — this buffer only
--   :FormatEnable   — re-enable both
vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, { desc = "Disable format-on-save (! = buffer only)", bang = true })

vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, { desc = "Re-enable format-on-save" })

-- Filetypes whose formatter has ever hit the sync timeout (cold dprint or a
-- first-run dotslash shim can take many seconds); they switch to async
-- format-after-save instead of freezing `:w` (conform's slow-formatter recipe).
local slow_format_filetypes = {}

return {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "dprint" },
    typescript = { "dprint" },
    typescriptreact = { "dprint" },
    javascript = { "dprint" },
    javascriptreact = { "dprint" },
    go = { "goimports", "gofumpt" },
    java = { "dprint" },
    json = { "dprint" },
    jsonc = { "dprint" },
    markdown = { "dprint" },
    rust = { "dprint" },
    sh = { "dprint" },
    toml = { "dprint" },
    yaml = { "dprint" },
    bzl = { "buildifier" },
    starlark = { "buildifier" },
    terraform = { "terraform_fmt" },
    ["terraform-vars"] = { "terraform_fmt" },
    hcl = { "terraform_fmt" },
    jsonnet = { "jsonnetfmt" },
  },
  formatters = {
    dprint = {
      command = repo_tool "tools/dprint/dprint",
      require_cwd = true,
    },
    terraform_fmt = {
      command = repo_tool "tools/dotslash/bin/terraform",
    },
    jsonnetfmt = {
      command = repo_tool "tools/dotslash/bin/jsonnetfmt",
      prepend_args = { "--string-style", "d", "--comment-style", "s" },
    },
  },
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    if slow_format_filetypes[vim.bo[bufnr].filetype] then
      return
    end
    local function on_format(err)
      if err and err:match "timeout$" then
        slow_format_filetypes[vim.bo[bufnr].filetype] = true
      end
    end
    return { timeout_ms = 3000, lsp_format = "fallback" }, on_format
  end,
  format_after_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    if not slow_format_filetypes[vim.bo[bufnr].filetype] then
      return
    end
    return { lsp_format = "fallback" }
  end,
}
