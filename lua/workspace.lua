-- Shared repo/tool discovery. Coder devboxes check Canva repos out under
-- ~/work; FFF resolves the repo for the current buffer, while LSP settings can
-- discover a repo-pinned tool such as tools/dotslash/bin/shellcheck. Cache the
-- directory listing so repeated tool lookups do not rescan the workspace.
local M = {
  root = vim.fn.expand "~/work",
}

local repos

local function absolute(path)
  if not path or path == "" then
    return nil
  end

  local result = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
  if result ~= "/" then
    result = result:gsub("/+$", "")
  end
  return vim.fs.normalize(result)
end

local function canonical(path)
  path = absolute(path)
  return path and vim.fs.normalize(vim.uv.fs_realpath(path) or path) or nil
end

local home = canonical(vim.env.HOME)
local work = canonical(M.root)

local function is_broad_root(path)
  path = canonical(path)
  return not path or path == "/" or path == home or path == work
end

local function root_from(path, is_file)
  local start = absolute(path)
  if not start then
    return nil
  end

  -- Find the lexical root first. Resolving a bazel-* symlink before walking
  -- parents can turn a Canva repo path into ~/.cache/bazel and lose .git.
  local git_root = vim.fs.root(start, ".git")
  if git_root and not is_broad_root(git_root) then
    return canonical(git_root)
  end

  -- Symlinked config paths can have no lexical .git marker, so try the real
  -- path only after the lexical walk has had a chance to keep the repo root.
  local real_start = canonical(start)
  local real_git_root = real_start and vim.fs.root(real_start, ".git")
  if real_git_root and not is_broad_root(real_git_root) then
    return canonical(real_git_root)
  end

  local fallback = is_file and vim.fs.dirname(start) or start
  if not is_broad_root(fallback) then
    return canonical(fallback)
  end
end

-- Resolve FFF to one repo/directory instead of the aggregate ~/work tree.
-- An explicit broad path is rejected so FFF's DirChanged handler cannot
-- accidentally index /, HOME (including a stray ~/.git), or all work repos.
-- Without an explicit path, prefer a safe cwd, then the current buffer, and
-- finally this small Neovim config checkout. This keeps :cd authoritative
-- while still handling the normal devbox cwd of the aggregate ~/work path.
M.project_root = function(path)
  if path then
    return root_from(path, false)
  end

  local cwd_root = root_from(vim.uv.cwd() or vim.fn.getcwd(), false)
  if cwd_root then
    return cwd_root
  end

  if vim.bo.buftype == "" then
    local buffer_path = vim.api.nvim_buf_get_name(0)
    local buffer_root = root_from(buffer_path, buffer_path ~= "")
    if buffer_root then
      return buffer_root
    end
  end

  return canonical(vim.fn.stdpath "config")
end

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
