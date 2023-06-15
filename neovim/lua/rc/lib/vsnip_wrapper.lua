local M = {}

local t = require('rc.lib.keybind').t

function M.jumpable(n)
  return b(vim.fn['vsnip#jumpable'](n))
end

function M.jump_next()
  -- if vim.fn.mode() == 's' then
  --   vim.api.nvim_feedkeys(t '<Esc>', 'i', false)
  -- end
  vim.api.nvim_feedkeys(t '<Plug>(vsnip-jump-next)', 'i', false)
end

function M.jump_prev()
  -- if vim.fn.mode() == 's' then
  --   vim.api.nvim_feedkeys(t '<Esc>', 'i', true)
  -- end
  vim.api.nvim_feedkeys(t '<Plug>(vsnip-jump-prev)', 'i', false)
end

function M.keyseq_jump_next()
  return t '<Plug>(vsnip-jump-next)'
end

function M.keyseq_i_jump_next()
  return M.keyseq_jump_next()
end

function M.keyseq_s_jump_next()
  return M.keyseq_jump_next()
end

function M.keyseq_jump_prev()
  return t '<Plug>(vsnip-jump-prev)'
end

function M.keyseq_i_jump_prev()
  return M.keyseq_jump_prev()
end

function M.keyseq_s_jump_prev()
  return M.keyseq_jump_prev()
end

function M.expandable()
  return b(vim.fn['vsnip#expandable']())
end

function M.expand()
  vim.fn['vsnip#expand']()
end

function M.anonymous(data)
  vim.fn['vsnip#anonymous'](data)
end

return M
