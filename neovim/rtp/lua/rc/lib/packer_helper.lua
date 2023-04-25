local M = {}

function M.config(mod)
  return load(string.format('require("%s").config()', mod))
end

function M.setup(mod)
  return load(string.format('require("%s").setup()', mod))
end

return M
