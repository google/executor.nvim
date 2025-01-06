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
local Executor = require("executor.executor")
local Output = require("executor.output")

local Public = {}

Public.setup = function(config)
  Executor.configure(config)
end

Public.statusline = function()
  return Output.statusline_output(Executor._state, Executor._settings.statusline)
end

Public.last_command = function()
  return {
    cmd = Executor._state.last_command,
    one_off = Executor._state.in_one_off_mode,
  }
end

Public.current_status = function()
  return Executor.current_status()
end

Public.commands = {
  reset = function()
    Executor.reset()
  end,
  swap_to_split = function()
    Executor.set_output_setting(true)
  end,
  swap_to_popup = function()
    Executor.set_output_setting(false)
  end,
  show_detail = function()
    Executor.show_detail()
  end,
  hide_detail = function()
    Executor.hide_detail()
  end,
  toggle_detail = function()
    Executor.toggle_detail()
  end,
  set_command = function()
    Executor.trigger_set_command_input("", function() end)
  end,
  run = function()
    Executor.run()
  end,
  show_presets = function()
    Output.preset_menu(Executor._stored_task_command, Executor._settings.preset_commands, function(chosen_option)
      if chosen_option == nil then
        return
      end
      if string.find(chosen_option, "[partial] ", 1, true) then
        local partial_command = chosen_option:gsub("%[partial%] ", ""):gsub("^%s*(.-)%s*$", "%1")
        Executor.trigger_set_command_input(partial_command, function()
          Executor.run()
        end)
      elseif string.find(chosen_option, "[current] ", 1, true) then
        -- No need to set the command, just run it, as the user has picked the current command.
        Executor.run()
      else
        Executor.set_task_command(chosen_option)
        Executor.run()
      end
    end)
  end,
  show_history = function()
    Output.history_menu(Executor._state.command_history, function(chosen_option)
      if chosen_option == nil then
        return
      end
      Executor.set_task_command(chosen_option)
      Executor.run()
    end)
  end,
  run_one_off = function(one_off_command)
    Executor.run_one_off_cmd(one_off_command)
  end,
}

vim.api.nvim_create_user_command("ExecutorReset", function()
  Public.commands.reset()
end, {})

vim.api.nvim_create_user_command("ExecutorSwapToSplit", function()
  Public.commands.swap_to_split()
end, {})

vim.api.nvim_create_user_command("ExecutorSwapToPopup", function()
  Public.commands.swap_to_popup()
end, {})

vim.api.nvim_create_user_command("ExecutorShowDetail", function()
  Public.commands.show_detail()
end, {})

vim.api.nvim_create_user_command("ExecutorHideDetail", function()
  Public.commands.hide_detail()
end, {})

vim.api.nvim_create_user_command("ExecutorToggleDetail", function()
  Public.commands.toggle_detail()
end, {})

vim.api.nvim_create_user_command("ExecutorSetCommand", function()
  Public.commands.set_command()
end, {})

vim.api.nvim_create_user_command("ExecutorRun", function()
  Public.commands.run()
end, { bang = true, nargs = "*" })

vim.api.nvim_create_user_command("ExecutorShowPresets", function()
  Public.commands.show_presets()
end, {})

vim.api.nvim_create_user_command("ExecutorShowHistory", function()
  Public.commands.show_history()
end, {})

vim.api.nvim_create_user_command("ExecutorOneOff", function(data)
  Public.commands.run_one_off(data.args)
end, { nargs = "*" })

return Public
