-- Shared ~/work repo/tool discovery. Coder devboxes check Canva repos out
-- under ~/work; FFF uses the common root, while LSP settings can discover a
-- repo-pinned tool such as tools/dotslash/bin/shellcheck. Cache the directory
-- listing so repeated lookups do not rescan the workspace.
local M = {
  root = vim.fn.expand "~/work",
}

local repos

-- Cached listing of the repo dirs under ~/work. isdirectory (not pcall)
-- guards machines without ~/work: pcall around readdir still lets the E484
-- message print.
local function work_repos()
  if repos then
    return repos
  end
  repos = {}
  local work = M.root
  if vim.fn.isdirectory(work) ~= 1 then
    return repos
  end
  for _, name in ipairs(vim.fn.readdir(work)) do
    table.insert(repos, work .. "/" .. name)
  end
  return repos
end

-- First repo dir under ~/work where the marker file is readable, or nil.
M.find_work_repo = function(marker)
  for _, dir in ipairs(work_repos()) do
    if vim.fn.filereadable(dir .. "/" .. marker) == 1 then
      return dir
    end
  end
  return nil
end

-- Absolute path of relpath in the first ~/work repo where it is executable,
-- else the bare tool name (PATH lookup still applies). Tools live in
-- different repos (jsonnetfmt is not in the dprint repo), so each relpath is
-- resolved independently rather than relative to one root.
M.find_work_tool = function(relpath)
  for _, dir in ipairs(work_repos()) do
    local bin = dir .. "/" .. relpath
    if vim.fn.executable(bin) == 1 then
      return bin
    end
  end
  return vim.fs.basename(relpath)
end

return M
