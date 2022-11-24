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
  Executor.trigger_set_command_input(function() end)
end, {})

vim.api.nvim_create_user_command("ExecutorRun", function()
  Executor.run()
end, { bang = true, nargs = "*" })

return Public
