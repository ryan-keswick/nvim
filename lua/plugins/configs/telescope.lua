local threads = vim.trim(vim.fn.system("nproc"))

return {
  defaults = {
    prompt_prefix = "   ",
    selection_caret = " ",
    entry_prefix = " ",
    sorting_strategy = "ascending",
    layout_config = {
      horizontal = { prompt_position = "top" },
    },
    file_ignore_patterns = {
      "bazel%-bin/", "bazel%-out/", "bazel%-testlogs/", "bazel%-links/",
      "node_modules/",
      "%.class$", "%.jar$", "%.pyc$",
    },
    vimgrep_arguments = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
      "--threads=" .. threads,
      "--no-follow",
      "--glob=!bazel-*",
      "--glob=!node_modules",
    },
  },
  pickers = {
    find_files = {
      find_command = { "fd", "--type", "f", "--no-follow", "--exclude", "bazel-*", "--exclude", "node_modules" },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
}
