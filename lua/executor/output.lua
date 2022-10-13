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

M.write_data = function(bufnr, input_lines)
  local trimmed_lines = {}
  for _, line in ipairs(input_lines) do
    if line ~= nil and line ~= "" then
      table.insert(trimmed_lines, line)
    end
  end
  local channel_id = vim.api.nvim_open_term(bufnr, {})
  vim.api.nvim_chan_send(channel_id, table.concat(trimmed_lines, "\n"))
end

return M
