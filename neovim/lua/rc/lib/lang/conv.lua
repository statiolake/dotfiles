local M = {}

function M.to_bool(vim_bool)
  if type(vim_bool) == 'boolean' then
    return vim_bool
  elseif type(vim_bool) == 'number' then
    return vim_bool ~= 0
  else
    return not (not vim_bool)
  end
end

return M
