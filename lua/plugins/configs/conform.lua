local workspace = require "workspace"

-- Repo-pinned tool fallbacks, resolved once against ~/work (lua/workspace.lua).
-- The per-buffer `command` functions below search upward from the buffer
-- first so every repo formats with its own pinned tool; these fallbacks only
-- kick in for files outside a repo (bare tool name if no ~/work repo has it).
local dprint_fallback = workspace.find_work_tool "tools/dprint/dprint"

-- `terraform fmt`: there is no bare `terraform` on PATH; repos ship a dotslash
-- shim at tools/dotslash/bin/terraform that reads stdin and formats fast.
-- Prefer that over the `tf` Bazel wrapper (which spins up Bazel on every
-- invocation — far too slow for format-on-save).
local terraform_fallback = workspace.find_work_tool "tools/dotslash/bin/terraform"

-- Repo-pinned jsonnetfmt: some ~/work repos (e.g. k8s) ship a dotslash shim
-- at tools/dotslash/bin/jsonnetfmt and enforce a house style in CI — k8s runs
-- `jsonnetfmt --string-style d --comment-style s` (double quotes), gated by
-- build/verify/verify_fmt.sh. Without this, bare `jsonnetfmt` is unresolved
-- and format-on-save falls back to the language server, which defaults to
-- single quotes and fights CI on every save.
local jsonnetfmt_fallback = workspace.find_work_tool "tools/dotslash/bin/jsonnetfmt"

-- Resolve a repo-pinned tool upward from the buffer's own directory (works
-- because vim.fs.find joins slash-containing names in upward mode), so a
-- buffer in repo A never formats with repo B's binary.
local function repo_tool(relpath, fallback)
  return function(_, ctx)
    return vim.fs.find(relpath, { path = ctx.dirname, upward = true })[1] or fallback
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
    terraform = { "terraform_fmt" },
    ["terraform-vars"] = { "terraform_fmt" },
    hcl = { "terraform_fmt" },
    jsonnet = { "jsonnetfmt" },
  },
  formatters = {
    dprint = {
      command = repo_tool("tools/dprint/dprint", dprint_fallback),
    },
    terraform_fmt = {
      command = repo_tool("tools/dotslash/bin/terraform", terraform_fallback),
    },
    jsonnetfmt = {
      command = repo_tool("tools/dotslash/bin/jsonnetfmt", jsonnetfmt_fallback),
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
