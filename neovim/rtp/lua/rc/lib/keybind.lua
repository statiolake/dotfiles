local FunctionRegistry = require 'rc.lib.function_registry'

-- range 系キーバインドのために使うヘルパー
vim.cmd [[
  function! LuaRangeKeybindHelper(fnstr) range
    execute printf('call %s(%d, %d)', a:fnstr, a:firstline, a:lastline)
  endfunction
]]

local M = {
  registry = FunctionRegistry.new('rc.lib.keybind', 'registry'),
}

---Replace termcodes in given string.
---@param str string @containing termcodes
---@return string
function M.t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

---Return <cmd>{str}<CR>
---@param str string @command to run
---@return string
function M.cmd(str)
  return '<cmd>' .. str .. '<CR>'
end

function M.add(mode, lhs, rhs, opts)
  opts = vim.tbl_extend(
    'keep',
    opts or {},
    { silent = true, replace_termcodes = true }
  )

  -- buffer
  local adder = vim.api.nvim_set_keymap
  if opts.buffer then
    opts.buffer = nil
    adder = function(m, l, r, o)
      vim.api.nvim_buf_set_keymap(0, m, l, r, o)
    end
  end

  -- replace_termcodes
  if opts.replace_termcodes then
    -- デフォルトで replace されるので何もする必要はない。
    opts.replace_termcodes = nil
  end

  if type(rhs) == 'function' then
    local fnstr = M.registry:register_for_vimscript(rhs)

    -- range
    if opts.range then
      -- これはデフォルトの nvim_set_keymap にはないので消しておく必要がある
      opts.range = nil
      -- a:firstline, a:lastline が呼び出せないので別のラッパーが必要
      -- Note: fnstr が require'...' というスタイルなので中がダブルクオートで
      -- ある必要がある
      rhs = string.format(':call LuaRangeKeybindHelper("%s")<CR>', fnstr)
    else
      if opts.expr ~= nil then
        rhs = string.format('%s()', fnstr)
      else
        rhs = M.cmd(string.format('call %s()', fnstr))
      end
    end
  end

  if rhs == nil then
    error(string.format("mapping for '" .. lhs .. "' is nil"))
    return
  end

  if type(mode) == 'string' then
    mode = { mode }
  end

  for _, m in ipairs(mode) do
    adder(m, lhs, rhs, opts)
  end
end

function M.delete(mode, lhs, opts)
  local deleter = vim.api.nvim_del_keymap
  if opts.buffer then
    opts.buffer = nil
    deleter = function(m, l)
      vim.api.nvim_buf_del_keymap(0, m, l)
    end
  end

  if type(mode) == 'string' then
    mode = { mode }
  end
  for _, m in ipairs(mode) do
    deleter(m, lhs)
  end
end

function M.nvo(lhs, rhs, opts)
  return M.add({ 'n', 'v', 'o' }, lhs, rhs, opts)
end

function M.nvono(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.nvo(lhs, rhs, opts)
end

function M.nvoun(lhs, opts)
  return M.delete({ 'n', 'v', 'o' }, lhs, opts)
end

function M.nx(lhs, rhs, opts)
  return M.add({ 'n', 'x' }, lhs, rhs, opts)
end

function M.nxno(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.nx(lhs, rhs, opts)
end

function M.nxun(lhs, opts)
  return M.delete({ 'n', 'x' }, lhs, opts)
end

function M.n(lhs, rhs, opts)
  return M.add('n', lhs, rhs, opts)
end

function M.nno(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.n(lhs, rhs, opts)
end

function M.nun(lhs, opts)
  return M.delete('n', lhs, opts)
end

function M.s(lhs, rhs, opts)
  return M.add('s', lhs, rhs, opts)
end

function M.sno(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.add('s', lhs, rhs, opts)
end

function M.sun(lhs, opts)
  return M.delete('s', lhs, opts)
end

function M.v(lhs, rhs, opts)
  return M.add('v', lhs, rhs, opts)
end

function M.vno(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.add('v', lhs, rhs, opts)
end

function M.vun(lhs, opts)
  return M.delete('v', lhs, opts)
end

function M.x(lhs, rhs, opts)
  return M.add('x', lhs, rhs, opts)
end

function M.xno(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.add('x', lhs, rhs, opts)
end

function M.xun(lhs, opts)
  return M.delete('x', lhs, opts)
end

function M.i(lhs, rhs, opts)
  return M.add('i', lhs, rhs, opts)
end

function M.ino(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.add('i', lhs, rhs, opts)
end

function M.iun(lhs, opts)
  return M.delete('i', lhs, opts)
end

function M.c(lhs, rhs, opts)
  return M.add('c', lhs, rhs, opts)
end

function M.cno(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.add('c', lhs, rhs, opts)
end

function M.cun(lhs, opts)
  return M.delete('c', lhs, opts)
end

M.buf = {}

function M.buf.add(mode, lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { buffer = true })
  return M.add(mode, lhs, rhs, opts)
end

function M.buf.delete(mode, lhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { buffer = true })
  return M.delete(mode, lhs, opts)
end

function M.buf.nvo(lhs, rhs, opts)
  return M.buf.add({ 'n', 'v', 'o' }, lhs, rhs, opts)
end

function M.buf.nvono(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.buf.nvo(lhs, rhs, opts)
end

function M.buf.nvoun(lhs, opts)
  return M.buf.delete({ 'n', 'v', 'o' }, lhs, opts)
end

function M.buf.nx(lhs, rhs, opts)
  return M.buf.add({ 'n', 'x' }, lhs, rhs, opts)
end

function M.buf.nxno(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.buf.nx(lhs, rhs, opts)
end

function M.buf.nxun(lhs, opts)
  return M.buf.delete({ 'n', 'x' }, lhs, opts)
end

function M.buf.n(lhs, rhs, opts)
  return M.buf.add('n', lhs, rhs, opts)
end

function M.buf.nno(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.buf.n(lhs, rhs, opts)
end

function M.buf.nun(lhs, opts)
  return M.buf.delete('n', lhs, opts)
end

function M.buf.v(lhs, rhs, opts)
  return M.buf.add('v', lhs, rhs, opts)
end

function M.buf.vno(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.buf.add('v', lhs, rhs, opts)
end

function M.buf.vun(lhs, opts)
  return M.buf.delete('v', lhs, opts)
end

function M.buf.x(lhs, rhs, opts)
  return M.buf.add('x', lhs, rhs, opts)
end

function M.buf.xno(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.buf.add('x', lhs, rhs, opts)
end

function M.buf.xun(lhs, opts)
  return M.buf.delete('x', lhs, opts)
end

function M.buf.s(lhs, rhs, opts)
  return M.buf.add('s', lhs, rhs, opts)
end

function M.buf.sno(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.buf.add('s', lhs, rhs, opts)
end

function M.buf.sun(lhs, opts)
  return M.buf.delete('s', lhs, opts)
end

function M.buf.i(lhs, rhs, opts)
  return M.buf.add('i', lhs, rhs, opts)
end

function M.buf.ino(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.buf.add('i', lhs, rhs, opts)
end

function M.buf.iun(lhs, opts)
  return M.buf.delete('i', lhs, opts)
end

function M.buf.c(lhs, rhs, opts)
  return M.buf.add('c', lhs, rhs, opts)
end

function M.buf.cno(lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts or {}, { noremap = true })
  return M.buf.add('c', lhs, rhs, opts)
end

function M.buf.cun(lhs, opts)
  return M.buf.delete('c', lhs, opts)
end

return M
