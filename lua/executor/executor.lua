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

local Popup = require("nui.popup")
local Split = require("nui.split")
local event = require("nui.utils.autocmd").event

local Output = require("executor.output")

local M = {}

local POPUP_WIDTH = math.floor(vim.o.columns * 3 / 5)
local POPUP_HEIGHT = vim.o.lines - 20
local SPLIT_WIDTH = math.floor(vim.o.columns * 1 / 4)

local table_contains = function(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

M._settings = {
  use_split = true,
  split = {
    position = "right",
    size = SPLIT_WIDTH,
  },
  popup = {
    width = POPUP_WIDTH,
    height = POPUP_HEIGHT,
    border = {
      padding = {
        top = 2,
        bottom = 2,
        left = 3,
        right = 3,
      },
      style = "rounded",
    },
  },
  preset_commands = {},
  output_filter = function(command, lines)
    return lines
  end,
  notifications = {
    task_started = true,
    task_completed = true,
    border = {
      padding = {
        top = 0,
        bottom = 0,
        left = 1,
        right = 1,
      },
      style = "rounded",
    },
  },
  statusline = {
    prefix = "Executor: ",
    icons = {
      in_progress = "…",
      failed = "✖ ",
      passed = "✓",
    },
  },
}

M.configure = function(config)
  M._settings = vim.tbl_deep_extend("force", M._settings, config)
end

M.trigger_set_command_input = function(initial_input_value, callback_fn)
  vim.ui.input({
    prompt = "[Executor.nvim] enter a command to run: ",
    default = initial_input_value or "",
  }, function(choice)
    M.set_task_command(choice)
    callback_fn()
  end)
end

M._stored_task_command = nil
M._state = {
  running = false,
  last_stdout = nil,
  last_exit_code = nil,
  -- Updated with the last command that was run. This will be
  -- updated for one_off tasks
  last_command = nil,
  last_command_was_one_off = false,
  showing_detail = false,
  notification_timer = nil,
  command_history = {},
}

M.reset = function()
  M._state.last_exit_code = nil
  M._state.last_stdout = nil
  M._state.running = false
  M._stored_task_command = nil
  M._state.last_command_was_one_off = false
  M._state.last_command = nil
end

M.set_task_command = function(cmd)
  M._stored_task_command = cmd
  if not table_contains(M._state.command_history, cmd) then
    table.insert(M._state.command_history, cmd)
  end
end

M._make_notification_popup = function(text)
  M._notification_popup = Popup({
    position = "95%",
    size = {
      width = #text,
      height = 1,
    },
    enter = false,
    focusable = false,
    zindex = 50,
    relative = "editor",
    border = {
      padding = M._settings.notifications.border.padding,
      style = M._settings.notifications.border.style,
    },
    buf_options = {
      modifiable = false,
      readonly = true,
    },
  })
  vim.api.nvim_buf_set_lines(M._notification_popup.bufnr, 0, 1, false, { text })
  M._notification_popup:mount()
end

M._make_popup = function(title, lines)
  M._popup = Popup({
    position = "50%",
    size = {
      width = M._settings.popup.width,
      height = M._settings.popup.height,
    },
    enter = true,
    focusable = true,
    zindex = 50,
    relative = "editor",
    border = {
      padding = M._settings.popup.border.padding,
      style = M._settings.popup.border.style,
      text = {
        top = title,
        top_align = "center",
      },
    },
    buf_options = {
      -- Has to be modifiable and readonly as we send data to it from chan_send.
      -- We also mount it before writing text, so that the chan_send command
      -- wraps the lines at the right width.
      modifiable = true,
      readonly = false,
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  })

  M._popup:mount()
  Output.write_data(M._stored_task_command, M._popup.bufnr, M._settings.output_filter, lines)

  -- Ensure if the user uses :q or similar to destroy it, that we tidy up.
  M._popup:on({ event.BufWinLeave }, function()
    vim.schedule(function()
      M._popup:unmount()
      M._popup = nil
      M._state.showing_detail = false
    end)
  end, { once = true })
end

M._make_split = function(lines)
  M._split = Split({
    position = M._settings.split.position,
    size = M._settings.split.size,
    -- Ensures the split is relative to the entire editor, not the active window.
    -- e.g. if you have two splits: A | B
    -- And the split configured to open on the right.
    -- With the "editor" setting, the split we open will always be to the right of B
    relative = "editor",
    enter = false,
    buf_options = {
      -- Has to be modifiable and readonly as we send data to it from chan_send.
      -- We also mount it before writing text, so that the chan_send command
      -- wraps the lines at the right width.
      modifiable = true,
      readonly = false,
    },
  })

  M._split:mount()
  Output.write_data(M._stored_task_command, M._split.bufnr, M._settings.output_filter, lines)
  -- Ensure if the user uses :q or similar to destroy it, that we tidy up.
  M._split:on({ event.BufWinLeave }, function()
    vim.schedule(function()
      if M._split ~= nil then
        M._split:unmount()
        M._split = nil
      end
      M._state.showing_detail = false
    end)
  end, { once = true })
end

M._collect_stdout = function(_, data)
  M._state.last_stdout = data
end
M._on_exit = function(_, exit_code)
  M._state.running = false
  M._state.last_exit_code = exit_code

  -- If we have a popup or split, we need to update it here. This ensures if
  -- the user hasn't closed the view between tests runs that we still update
  -- it.

  local output = Output.output_for_state(M._state)
  if M._popup and M._popup.winid then
    Output.write_data(M._stored_task_command, M._popup.bufnr, M._settings.output_filter, output)
  end
  if M._split and M._split.winid then
    Output.write_data(M._stored_task_command, M._split.bufnr, M._settings.output_filter, output)
  end

  if M._settings.notifications.task_completed then
    if exit_code > 0 then
      M._show_notification("✖  Task errored", true)
    else
      M._show_notification("✓ Task success!", true)
    end
  end
  -- Force the statusline to redraw.
  vim.api.nvim_exec([[let &stl=&stl]], false)
end

M._show_notification = function(text, timeout)
  if M._state.notification_timer ~= nil then
    M._state.notification_timer:close()
    M._state.notification_timer = nil
  end

  if M._notification_popup ~= nil then
    M._notification_popup:unmount()
    M._notification_popup = nil
  end

  M._make_notification_popup(text)
  if timeout then
    M._state.notification_timer = vim.loop.new_timer()
    M._state.notification_timer:start(
      5000,
      0,
      vim.schedule_wrap(function()
        M._notification_popup:unmount()
        M._state.notification_timer:close()
        M._state.notification_timer = nil
      end)
    )
  end
end

M.run_task = function(one_off_command)
  if M._popup ~= nil then
    M._popup:unmount()
    M._popup = nil
  end

  -- Empty the split before re-running. This ensures that the
  -- next run is outputted correctly with no weird chunks of whitespace.
  if M._split ~= nil and M._split.bufnr ~= nil then
    local channel_id = vim.api.nvim_open_term(M._split.bufnr, {})
    vim.api.nvim_chan_send(channel_id, "")
  end

  local cmd = one_off_command or M._stored_task_command
  if cmd == nil then
    return
  end
  M._state.last_command = cmd
  M._state.last_command_was_one_off = one_off_command ~= nil

  M._state.running = true
  if M._settings.notifications.task_started then
    M._show_notification("⟳ " .. M._stored_task_command, false)
  end
  -- Force the statusline to redraw.
  vim.api.nvim_exec([[let &stl=&stl]], false)

  vim.fn.jobstart(cmd, {
    -- pty means that stderr is ignored, and all output goes to stdout, so
    -- that's why stderr is ignored here.
    pty = true,
    -- width = 50,
    stdout_buffered = true,
    on_stdout = M._collect_stdout,
    on_exit = M._on_exit,
  })
end

M._show_popup = function()
  -- If winid is nil, the user may have :q it, so we need to recreate it.
  if M._popup and M._popup.winid == nil then
    M._popup:unmount()
    M._popup = nil
  end

  if M._popup == nil then
    local title = "Finished: " .. M._state.last_command
    local output = Output.output_for_state(M._state)

    if M._state.last_exit_code > 0 then
      title = "Task error"
    end
    M._make_popup(title, output)
  else
    M._popup:show()
  end
end

M._show_split = function()
  -- If winid is nil, the user may have :q it, so we need to recreate it.
  if M._split and M._split.winid == nil then
    M._split:unmount()
    M._split = nil
  end
  if M._split == nil then
    local output = Output.output_for_state(M._state)
    M._make_split(output)
  else
    M._split:show()
  end
end

M.toggle_detail = function()
  -- Don't attempt to show detail if no tests have been run.
  if M._state.last_stdout == nil then
    Output.write_data(nil, nil, nil, nil)
    return
  end
  if M._state.showing_detail == true then
    -- Need to ensure that we definitely are still showing the detail
    -- If the user has `:q` on the detail view, we might have the flag set to `true` but it actually have gone.
    local actually_showing_detail = (M._popup and M._popup.winid) or (M._split and M._split.winid)
    if actually_showing_detail then
      M.hide_detail()
    else
      M.show_detail()
    end
  else
    M.show_detail()
  end
end

M.set_output_setting = function(use_split)
  M._settings.use_split = use_split
end

M.show_detail = function()
  M._state.showing_detail = true
  if M._settings.use_split then
    M._show_split()
  else
    M._show_popup()
  end
end

M.hide_detail = function()
  M._state.showing_detail = false

  if M._settings.use_split then
    if M._split ~= nil then
      M._split:hide()
    end
  else
    if M._popup ~= nil then
      M._popup:hide()
    end
  end
end

M.run = function(one_off_command)
  if one_off_command ~= nil then
    M.run_task(one_off_command)
    return
  end
  if M._stored_task_command == nil then
    M.trigger_set_command_input("", function()
      M.run_task()
    end)
  else
    M.run_task()
  end
end

M.current_status = function()
  local state = M._state
  local never_run = state.last_exit_code == nil and state.running == false

  if never_run then
    return "NEVER_RUN"
  end

  if state.running then
    return "IN_PROGRESS"
  end

  if state.last_exit_code == 0 then
    return "PASSED"
  end

  return "FAILED"
end

return M
