local threads = vim.trim(vim.fn.system("nproc"))

local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }
local spinner_idx = 0
local spinner_timer = nil

local function stop_spinner()
  if spinner_timer then
    spinner_timer:stop()
    spinner_timer:close()
    spinner_timer = nil
  end
end

local function start_spinner(status_updater)
  stop_spinner()
  spinner_timer = vim.loop.new_timer()
  spinner_timer:start(0, 80, vim.schedule_wrap(function()
    spinner_idx = (spinner_idx + 1) % #spinner_frames
    status_updater { completed = false }
  end))
end

local function get_status_text(self, opts)
  local completed = opts and opts.completed
  if not completed and not spinner_timer then
    local updater = self:get_status_updater(self.prompt_win, self.prompt_bufnr)
    start_spinner(updater)
  elseif completed then
    stop_spinner()
  end

  local multi_select_cnt = #(self:get_multi_selection())
  local showing_cnt = (self.stats.processed or 0) - (self.stats.filtered or 0)
  local total_cnt = self.stats.processed or 0

  local status_icon = completed and "" or spinner_frames[spinner_idx + 1]

  local status_text
  if showing_cnt == 0 and total_cnt == 0 then
    status_text = status_icon
  elseif multi_select_cnt == 0 then
    status_text = string.format("%s %s / %s", status_icon, showing_cnt, total_cnt)
  else
    status_text = string.format("%s %s / %s / %s", status_icon, multi_select_cnt, showing_cnt, total_cnt)
  end

  -- workaround for extmark right_align side-scrolling limitation
  -- https://github.com/nvim-telescope/telescope.nvim/issues/2929
  local prompt_width = vim.api.nvim_win_get_width(self.prompt_win)
  local cursor_col = vim.api.nvim_win_get_cursor(self.prompt_win)[2]
  local strings = require("plenary.strings")
  local prefix_display_width = strings.strdisplaywidth(self.prompt_prefix)
  local prefix_width = #self.prompt_prefix
  local prefix_shift = prefix_display_width ~= prefix_width and prefix_display_width or 0
  if (prompt_width - cursor_col - #status_text + prefix_shift) < 0 then
    return ""
  end
  return status_text
end

return {
  defaults = {
    prompt_prefix = "   ",
    selection_caret = " ",
    entry_prefix = " ",
    sorting_strategy = "ascending",
    get_status_text = get_status_text,
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
