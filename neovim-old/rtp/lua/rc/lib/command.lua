local FunctionRegistry = require 'rc.lib.function_registry'

local M = {
  registry = FunctionRegistry.new('rc.lib.command', 'registry'),
}

---@param name string
---@param func fun(table)|string
---@param opts? table
function M.add(name, func, opts)
  if type(func) == 'string' then
    -- 元々の文字列を保存しておく必要がある
    local cmd = func
    func = function()
      vim.cmd(cmd)
    end
  end

  -- exposure function in globally available __autofuncs
  local fnstr = M.registry:register_for_vimscript(func, name)

  opts = opts or {}
  local ctxexpr = {}
  local optstr = ''

  if opts.nargs ~= nil then
    optstr = optstr .. string.format('-nargs=%s ', opts.nargs)
    ctxexpr.args = '[<f-args>]'
  end

  if opts.complete ~= nil then
    local cmpfnstr =
      M.registry:register_for_vimscript(opts.complete, name .. '_complete')
    optstr = optstr .. string.format('-complete=customlist,%s ', cmpfnstr)
  end

  if opts.bang then
    optstr = optstr .. '-bang '
    ctxexpr.bang = '"<bang>" ==# "!" ? v:true : v:false'
  end

  if opts.range then
    optstr = optstr .. '-range '
    ctxexpr.range = '{ "first": <line1>, "last": <line2> }'
  end

  local ctxexprstr = table
    .iter(ctxexpr, pairs)
    :map(function(k, v)
      return string.format('"%s": %s', k, v)
    end)
    :fold('', function(s, e)
      return s == '' and e or (s .. ', ' .. e)
    end)
  ctxexprstr = '{ ' .. ctxexprstr .. ' }'

  vim.cmd(
    string.format(
      'command! %s %s call %s(%s)',
      optstr,
      name,
      fnstr,
      ctxexprstr
    )
  )
end

function M.delete(name)
  vim.cmd('delcommand ' .. name)
end

return M
