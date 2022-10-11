local Executor = require("executor.executor")

local Public = {}

Public.setup = function(config)
  Executor.configure(config)
end

vim.api.nvim_create_user_command("V2ShowPopup", function()
  Executor.show_popup()
end, {})

vim.api.nvim_create_user_command("V2HidePopup", function()
  Executor.hide_popup()
end, {})

vim.api.nvim_create_user_command("V2SetTaskCommand", function()
  Executor.trigger_set_command_input(function() end)
end, {})

-- TODO: take input for one-off?
vim.api.nvim_create_user_command("V2TaskRunner", function()
  Executor.run()
end, { bang = true, nargs = "*" })

return Public
