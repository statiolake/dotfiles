local FunctionRegistry = require 'rc.lib.function_registry'

local M = {
  registry = FunctionRegistry.new('rc.lib.autocmd', 'registry'),
}

local function autocmd(registry_basename, event, pattern, func, opts)
  -- concat event names
  if type(event) == 'table' then
    event = table.concat(event, ',')
  end

  if type(func) == 'string' then
    -- 元々の文字列を保存しておく必要がある
    local cmd = func
    func = function()
      vim.cmd(cmd)
    end
  end

  local optstr = {}
  if opts and opts.once then
    table.insert(optstr, '++once')
  end
  optstr = table.concat(optstr, ' ')

  -- register function
  local fnstr = M.registry:register_for_vimscript(func, registry_basename)
  local callexpr = string.format('call %s()', fnstr)

  if opts and opts.guarded_filetypes then
    local quoted = table
      .iter_values(opts.guarded_filetypes, ipairs)
      :map(function(v)
        return string.format([['%s']], v)
      end)
      :to_table()
    callexpr = string.format(
      'if index([%s], &ft) ==# -1 | %s | endif',
      table.concat(quoted, ', '),
      callexpr
    )
  end

  vim.cmd(
    string.format('autocmd %s %s %s %s', event, pattern, optstr, callexpr)
  )
end

---@param autocmds_callback fun(au: fun(event: table|string, pattern: string, func: fun()|string, opts?: table))
function M.augroup(name, autocmds_callback)
  vim.cmd(string.format('augroup %s', name))
  vim.cmd [[autocmd!]]
  autocmds_callback(function(event, pattern, any, opts)
    return autocmd(name, event, pattern, any, opts)
  end)
  vim.cmd [[augroup END]]
end

function M.register_once(event, pattern, func)
  autocmd(nil, event, pattern, func, { once = true })
end

function M.on_vimenter(func)
  M.register_once('VimEnter', '*', func)
end

function M.on_uienter(func)
  M.register_once('UIEnter', '*', func)
end

function M.on_vim_started(func)
  M.register_once('CursorHold', '*', func)
end

function M.emit(event, arg)
  vim.cmd(string.format('doautocmd %s %s', event, arg))
end

return M
