local M = {}

M.has_placeholder = function(input_string)
  return string.find(input_string, "$E_FN", 1, 1) ~= nil
end

M.replace_placeholders = function(input_string, file_name)
  if file_name == nil then
    return input_string
  end

  return string.gsub(input_string, "$E_FN", file_name)
end

return M
