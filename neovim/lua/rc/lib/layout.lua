local M = {}

function M.get_preferred_split()
  if vim.fn.winwidth(0) < vim.fn.winheight(0) * 3 then
    -- 縦長
    return 'split'
  else
    -- 横長
    return 'vsplit'
  end
end

return M
