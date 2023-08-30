--[[
Copyright 2022 Google LLC
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]

local M = {}

M.output_for_state = function(state)
  -- All output is directed to stdout.
  local output = state.last_stdout
  return output
end

M.statusline_output = function(state)
  -- We only output to the statusline if either:
  -- 1) we are running currently
  -- 2) we have a prior result to show
  if state.last_exit_code == nil and state.running == false then
    return ""
  end

  local prefix = "[Executor: "
  local suffix = "]"
  -- By default, assume the test failed.
  local result = "✖ "

  if state.running then
    result = "…"
  elseif state.last_exit_code == 0 then
    result = "✓"
  end

  return prefix .. result .. suffix
end

M._clean_lines = function(input_lines)
  local trimmed_lines = {}
  -- We want to do tidy up on the start of the input and:
  -- 1) remove any lines that are an empty string.
  -- 2) remove any line-breaks
  -- We don't want to tidy up any empty lines within the input as CLI tools
  -- often use empty lines to break output up and make it more readable.
  local seen_populated_line = false
  for _, line in ipairs(input_lines) do
    if seen_populated_line then
      table.insert(trimmed_lines, line)
    else
      local should_keep_line = line ~= nil and line ~= "" and line ~= "\n" and line ~= "\r"
      if should_keep_line then
        seen_populated_line = true
        table.insert(trimmed_lines, line)
      end
    end
  end
  return trimmed_lines
end

M.process_lines = function(cmd, filter_function, input_lines)
  return filter_function(cmd, M._clean_lines(input_lines))
end

M.write_data = function(cmd, bufnr, filter_function, input_lines)
  local trimmed_lines = filter_function(cmd, M._clean_lines(input_lines))
  local channel_id = vim.api.nvim_open_term(bufnr, {})
  vim.api.nvim_chan_send(channel_id, table.concat(trimmed_lines, "\n"))
end

M.preset_menu = function(preset_commands_by_directory, callback_after_choice)
  local Menu = require("nui.menu")
  local cwd = vim.loop.cwd()
  local found_options = {}
  for directory_name, directory_commands in pairs(preset_commands_by_directory) do
    if string.find(cwd, directory_name, 1, true) then
      for _, command in ipairs(directory_commands) do
        if type(command) == "string" then
          table.insert(found_options, Menu.item(command))
        elseif command.partial == true then
          local final_cmd = command.cmd
          if type(command.cmd) == "function" then
            final_cmd = command.cmd()
          end
          table.insert(found_options, Menu.item("[partial] " .. final_cmd))
        elseif type(command.cmd) == "function" then
          -- Allow a command to be a function that is executed per-buffer.
          local final_cmd = command.cmd()
          table.insert(found_options, Menu.item(final_cmd))
        end
      end
    end
  end

  if #found_options == 0 then
    print("Executor.nvim: No stored commands found for this working directory.")
    return
  end

  local menu = Menu({
    position = "50%",
    relative = "editor",
    size = {
      width = "80%",
      height = math.max(10, #found_options),
    },
    border = {
      style = "single",
      text = {
        top = "Executor.nvim: choose a command",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    lines = found_options,
    max_width = 45,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>", "q" },
      submit = { "<CR>", "<Space>" },
    },
    on_submit = function(item)
      callback_after_choice(item.text)
    end,
  })
  menu:mount()
end
M.history_menu = function(command_history, callback_after_choice)
  if #command_history == 0 then
    print("Executor.nvim: No command history to show.")
    return
  end

  local Menu = require("nui.menu")
  local menu_items = {}
  for key, command in pairs(command_history) do
    table.insert(menu_items, Menu.item(command))
  end

  local menu = Menu({
    position = "50%",
    relative = "editor",
    size = {
      width = "80%",
      height = math.max(10, #command_history),
    },
    border = {
      style = "single",
      text = {
        top = "Executor.nvim: choose a command from the history",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    lines = menu_items,
    max_width = 45,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>", "q" },
      submit = { "<CR>", "<Space>" },
    },
    on_submit = function(item)
      callback_after_choice(item.text)
    end,
  })
  menu:mount()
end

return M
