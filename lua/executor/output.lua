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
