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

return {
  formatters_by_ft = {
    python          = { "dprint" },
    typescript      = { "dprint" },
    typescriptreact = { "dprint" },
    javascript      = { "dprint" },
    javascriptreact = { "dprint" },
    go              = { "dprint" },
    java            = { "dprint" },
    json            = { "dprint" },
    jsonc           = { "dprint" },
    markdown        = { "dprint" },
    rust            = { "dprint" },
    sh              = { "dprint" },
    toml            = { "dprint" },
    yaml            = { "dprint" },
  },
  formatters = {
    dprint = {
      command = dprint_cmd,
    },
  },
  format_on_save = {
    timeout_ms = 10000,
    lsp_format = "never",
  },
}
