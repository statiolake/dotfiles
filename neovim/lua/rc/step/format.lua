local cmd = require 'rc.lib.command'

local fmt = require 'rc.lib.format'
fmt.setup()
cmd.add('W', function(ctx)
  fmt.save_without_format('write' .. (ctx.bang and '!' or ''))
end, { nargs = '0', bang = true })
cmd.add('WA', function(ctx)
  fmt.save_without_format('wall' .. (ctx.bang and '!' or ''))
end, { nargs = '0', bang = true })
