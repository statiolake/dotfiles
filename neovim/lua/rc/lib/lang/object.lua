local M = {}

function M.deepcopy(obj)
  if type(obj) == 'table' then
    local copied = {}
    for key, value in pairs(obj) do
      copied[M.deepcopy(key)] = M.deepcopy(value)
    end
    setmetatable(copied, M.deepcopy(getmetatable(obj)))
    return copied
  else
    return obj
  end
end

function M.inspect(...)
  vim.api.nvim_echo({ { vim.inspect { ... } } }, true, {})
  return ...
end

return M
