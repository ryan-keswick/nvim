return {
  filters = { dotfiles = false },
  disable_netrw = true,
  -- Bazel convenience symlinks (bazel-out, bazel-<repo>, external) point into
  -- the output base under ~/.cache/bazel with hundreds of thousands of
  -- directories. Watching them exhausts fs.inotify.max_user_watches and every
  -- failed watcher raises an ENOSPC hit-enter prompt that blocks the editor.
  filesystem_watchers = {
    enable = true,
    ignore_dirs = {
      "/.ccls-cache",
      "/build",
      "/node_modules",
      "/target",
      "/.zig-cache",
      "/.cache/bazel/",
      "bazel-out",
      "bazel-bin",
      "bazel-testlogs",
    },
  },
  hijack_cursor = true,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = false,
  },
  view = {
    side = "left",
    width = { min = 30, max = 60, padding = 1 },
    preserve_window_proportions = true,
  },
  renderer = {
    root_folder_label = false,
    highlight_git = true,
    indent_width = 1,
    indent_markers = { enable = true },
    icons = {
      glyphs = {
        default = "󰈚",
        folder = {
          default = "",
          empty = "",
          empty_open = "",
          open = "",
          symlink = "",
        },
        git = { unmerged = "" },
      },
    },
  },
}
