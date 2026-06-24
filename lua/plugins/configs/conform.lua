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
  },
  format_on_save = {
    timeout_ms = 10000,
    lsp_format = "fallback",
  },
}
