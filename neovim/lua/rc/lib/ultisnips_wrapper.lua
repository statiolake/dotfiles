local M = {}

local t = require('rc.lib.keybind').t

function M.jumpable(n)
  if n == 1 then
    return b(vim.fn['UltiSnips#CanJumpForwards']())
  elseif n == -1 then
    return b(vim.fn['UltiSnips#CanJumpBackwards']())
  else
    return false
  end
end

function M.jump_next()
  vim.fn['UltiSnips#JumpForwards']()
end

---@param mode? string 'i' for insert mode, select mode otherwise
function M.keyseq_jump_next(mode)
  mode = mode or vim.fn.mode():sub(1, 1)
  return mode == 'i' and M.keyseq_i_jump_next() or M.keyseq_s_jump_next()
end

function M.keyseq_i_jump_next()
  return t '<C-r>=UltiSnips#JumpForwards()?"":""<CR>'
end

function M.keyseq_s_jump_next()
  return t '<Esc>:call UltiSnips#JumpForwards()<CR>'
end

function M.jump_prev()
  vim.fn['UltiSnips#JumpBackwards']()
end

---@param mode? string 'i' for insert mode, select mode otherwise
function M.keyseq_jump_prev(mode)
  mode = mode or vim.fn.mode():sub(1, 1)
  return mode == 'i' and M.keyseq_i_jump_prev() or M.keyseq_s_jump_prev()
end

function M.keyseq_i_jump_prev()
  return t '<C-r>=UltiSnips#JumpBackwards()?"":""<CR>'
end

function M.keyseq_s_jump_prev()
  return t '<Esc>:call UltiSnips#JumpBackwards()<CR>'
end

function M.expandable()
  return not b(vim.fn.empty(vim.fn['UltiSnips#SnippetsInCurrentScope']()))
end

function M.expand()
  vim.fn['UltiSnips#ExpandSnippet']()
end

function M.anonymous(data)
  vim.fn['UltiSnips#Anon'](data)
end

return M
