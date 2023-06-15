local M = {}

function M.link(target, source)
  vim.cmd(string.format('hi! link %s %s', target, source))
end

function M.define(target, opts)
  if not opts or opts == {} then
    return
  end

  local cmd = 'hi! ' .. target
  for k, v in pairs(opts) do
    cmd = string.format('%s %s=%s', cmd, k, v)
  end
  vim.cmd(cmd)
end

return M
