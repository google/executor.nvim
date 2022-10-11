local Popup = require("nui.popup")
local Input = require("nui.input")
local event = require("nui.utils.autocmd").event

local M = {}

M._settings = {
  use_ansi_esc_plugin = false,
}

M.configure = function(config)
  M._settings.use_ansi_esc_plugin = config.use_ansi_esc_plugin
end

M.trigger_set_command_input = function(callback_fn)
  local input_component = Input({
    position = "50%",
    size = {
      width = 50,
    },
    border = {
      style = "single",
      text = {
        top = "Commmand to run:",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    prompt = "> ",
    default_value = "",
    on_submit = function(value)
      M._stored_task_command = value
      callback_fn()
    end,
  })

  input_component:mount()
  input_component:on(event.BufLeave, function()
    input_component:unmount()
  end)
end

M._stored_task_command = nil
M._state = {
  running = false,
  last_stdout = nil,
  last_stderr = nil,
  last_exit_code = nil,
}

M.set_task_command = function(cmd)
  M._stored_task_command = cmd
end

M._make_notification_popup = function(text)
  M._notification_popup = Popup({
    position = "95%",
    size = {
      width = 14,
      height = 1,
    },
    enter = false,
    focusable = false,
    zindex = 50,
    relative = "win",
    border = {
      padding = {
        top = 0,
        bottom = 0,
        left = 1,
        right = 1,
      },
      style = "rounded",
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
      width = 80,
      height = 40,
    },
    enter = true,
    focusable = true,
    zindex = 50,
    relative = "win",
    border = {
      padding = {
        top = 2,
        bottom = 2,
        left = 3,
        right = 3,
      },
      style = "rounded",
      text = {
        top = title,
        top_align = "center",
      },
    },
    buf_options = {
      modifiable = false,
      readonly = true,
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  })

  local trimmed_lines = {}
  for _, line in ipairs(lines) do
    if line ~= nil and line ~= "" then
      local line_to_store = line
      if M._settings.use_ansi_esc_plugin == false then
        line_to_store = line
          :gsub("\x1b%[%d+;%d+;%d+;%d+;%d+m", "")
          :gsub("\x1b%[%d+;%d+;%d+;%d+m", "")
          :gsub("\x1b%[%d+;%d+;%d+m", "")
          :gsub("\x1b%[%d+;%d+m", "")
          :gsub("\x1b%[%d+m", "")
      end

      table.insert(trimmed_lines, line_to_store)
    end
  end
  vim.api.nvim_buf_set_lines(M._popup.bufnr, 0, 1, false, trimmed_lines)
  M._popup:mount()
  if M._settings.use_ansi_esc_plugin then
    vim.api.nvim_cmd({ cmd = "AnsiEsc" }, { output = false })
  end
  -- Ensure if the user uses :q or similar to destroy it, that we tidy up.
  M._popup:on({ event.BufWinLeave }, function()
    vim.schedule(function()
      M._popup:unmount()
      M._popup = nil
    end)
  end, { once = true })
end

M._collect_stdout = function(_, data)
  M._state.last_stdout = data
end
M._collect_stderr = function(_, data)
  M._state.last_stderr = data
end
M._on_exit = function(_, exit_code)
  M._state.running = false
  M._state.last_exit_code = exit_code
  if exit_code > 0 then
    M._show_notification("✖ Task errored", true)
  else
    M._show_notification("✓ Task success!", true)
  end
end

M._show_notification = function(text, timeout)
  if M._notification_popup ~= nil then
    M._notification_popup:unmount()
    M._notification_popup = nil
  end
  M._make_notification_popup(text)
  if timeout then
    local timer = vim.loop.new_timer()
    timer:start(
      5000,
      0,
      vim.schedule_wrap(function()
        M._notification_popup:unmount()
      end)
    )
  end
end

M.run_task = function()
  if M._popup ~= nil then
    M._popup:unmount()
    M._popup = nil
  end

  if M._stored_task_command == nil then
    return
  end

  M._state.running = true

  M._show_notification("Running...", false)

  vim.fn.jobstart(M._stored_task_command, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = M._collect_stdout,
    on_stderr = M._collect_stderr,
    on_exit = M._on_exit,
  })
end

M.show_popup = function()
  -- If winid is nill, the user may have :q it, so we need to recreate it.
  if M._popup and M._popup.winid == nil then
    M._popup:unmount()
    M._popup = nil
  end

  if M._popup == nil then
    M._popup = nil
    local title = "Task finished"
    local output = M._state.last_exit_code > 0 and M._state.last_stderr or M._state.last_stdout
    -- Sometimes issues go to stdout.
    if M._state.last_exit_code > 0 and #output == 1 and output[1] == "" then
      output = M._state.last_stdout
    end
    print(vim.inspect(M._state))

    if M._state.last_exit_code > 0 then
      title = "Task error"
    end
    M._make_popup(title, output)
  else
    M._popup:show()
  end
end

M.hide_popup = function()
  if M._popup ~= nil then
    M._popup:hide()
  end
end

-- M._make_notification_popup()
-- M._make_popup()

-- M.run_task()

M.run = function()
  if M._stored_task_command == nil then
    M.trigger_set_command_input(function()
      M.run_task()
    end)
  else
    M.run_task()
  end
end

return M
