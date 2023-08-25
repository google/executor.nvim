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
  return Output.statusline_output(Executor._state)
end

vim.api.nvim_create_user_command("ExecutorReset", function()
  Executor.reset()
end, {})

vim.api.nvim_create_user_command("ExecutorSwapToSplit", function()
  Executor.set_output_setting(true)
end, {})

vim.api.nvim_create_user_command("ExecutorSwapToPopup", function()
  Executor.set_output_setting(false)
end, {})

vim.api.nvim_create_user_command("ExecutorShowDetail", function()
  Executor.show_detail()
end, {})

vim.api.nvim_create_user_command("ExecutorHideDetail", function()
  Executor.hide_detail()
end, {})

vim.api.nvim_create_user_command("ExecutorToggleDetail", function()
  Executor.toggle_detail()
end, {})

vim.api.nvim_create_user_command("ExecutorSetCommand", function()
  Executor.trigger_set_command_input("", function() end)
end, {})

vim.api.nvim_create_user_command("ExecutorRun", function()
  Executor.run()
end, { bang = true, nargs = "*" })

vim.api.nvim_create_user_command("ExecutorShowPresets", function()
  Output.preset_menu(Executor._settings.preset_commands, function(chosen_option)
    if string.find(chosen_option, "[partial] ", 1, true) then
      local partial_command = chosen_option:gsub("%[partial%] ", ""):gsub("^%s*(.-)%s*$", "%1")
      Executor.trigger_set_command_input(partial_command, function()
        Executor.run()
      end)
    else
      Executor.set_task_command(chosen_option)
      Executor.run()
    end
  end)
end, {})

vim.api.nvim_create_user_command("ExecutorShowHistory", function()
  Output.history_menu(Executor._state.command_history, function(chosen_option)
    Executor.set_task_command(chosen_option)
    Executor.run()
  end)
end, {})

return Public
