local function find_bazel_workspace()
  local work = vim.fn.expand("~/work")
  for _, name in ipairs(vim.fn.readdir(work) or {}) do
    local dir = work .. "/" .. name
    if vim.fn.filereadable(dir .. "/tools/dprint/dprint") == 1 then
      return dir
    end
  end
  return nil
end

local workspace = find_bazel_workspace()
local workspace_dprint = workspace and (workspace .. "/tools/dprint/dprint") or ""
local dprint_cmd = vim.fn.filereadable(workspace_dprint) == 1 and workspace_dprint or "dprint"

-- Resolve a terraform binary for `terraform fmt`. There is no bare `terraform`
-- on PATH; repos ship a dotslash shim at tools/dotslash/bin/terraform that reads
-- stdin and formats fast. Prefer that over the `tf` Bazel wrapper (which spins up
-- Bazel on every invocation — far too slow for format-on-save).
local function find_terraform()
  local work = vim.fn.expand("~/work")
  for _, name in ipairs(vim.fn.readdir(work) or {}) do
    local bin = work .. "/" .. name .. "/tools/dotslash/bin/terraform"
    if vim.fn.executable(bin) == 1 then
      return bin
    end
  end
  return "terraform"
end

local terraform_cmd = find_terraform()

-- Resolve a repo-pinned jsonnetfmt. Some ~/work repos (e.g. k8s) ship a dotslash
-- shim at tools/dotslash/bin/jsonnetfmt and enforce a house style in CI — k8s
-- runs `jsonnetfmt --string-style d --comment-style s` (double quotes), gated by
-- build/verify/verify_fmt.sh. Without this, bare `jsonnetfmt` is unresolved and
-- format-on-save falls back to the language server, which defaults to single
-- quotes and fights CI on every save.
local function find_jsonnetfmt()
  local work = vim.fn.expand("~/work")
  for _, name in ipairs(vim.fn.readdir(work) or {}) do
    local bin = work .. "/" .. name .. "/tools/dotslash/bin/jsonnetfmt"
    if vim.fn.executable(bin) == 1 then
      return bin
    end
  end
  return "jsonnetfmt"
end

local jsonnetfmt_cmd = find_jsonnetfmt()

return {
  formatters_by_ft = {
    python          = { "dprint" },
    typescript      = { "dprint" },
    typescriptreact = { "dprint" },
    javascript      = { "dprint" },
    javascriptreact = { "dprint" },
    go              = { "goimports", "gofumpt" },
    java            = { "dprint" },
    json            = { "dprint" },
    jsonc           = { "dprint" },
    markdown        = { "dprint" },
    rust            = { "dprint" },
    sh              = { "dprint" },
    toml            = { "dprint" },
    yaml            = { "dprint" },
    bzl             = { "buildifier" },
    terraform       = { "terraform_fmt" },
    ["terraform-vars"] = { "terraform_fmt" },
    hcl             = { "terraform_fmt" },
    jsonnet         = { "jsonnetfmt" },
  },
  formatters = {
    dprint = {
      command = dprint_cmd,
    },
    terraform_fmt = {
      command = terraform_cmd,
    },
    jsonnetfmt = {
      command = jsonnetfmt_cmd,
      prepend_args = { "--string-style", "d", "--comment-style", "s" },
    },
  },
  format_on_save = {
    timeout_ms = 10000,
    lsp_format = "fallback",
  },
}
