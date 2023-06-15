local M = {}

local msg = require 'rc.lib.msg'

local supported = pcall(vim.cmd, 'packadd plenary.nvim')

local profile_or_err = 'packadd plenary.nvim failed'
if supported then
  supported, profile_or_err = pcall(require, 'plenary.profile.p')
end

function M.start(file)
  if supported then
    profile_or_err.start('10,i1,zf,m0,G', file)
    return true
  else
    msg.warn('profiling is unavailable: %s', profile_or_err)
    return false
  end
end

function M.stop()
  if supported then
    profile_or_err.stop()
  end
end

function M.zone(tag, inner)
  local ok, zone = pcall(require, 'jit.zone')
  if ok then
    zone(tag)
  end

  local res = { inner() }

  if ok then
    zone()
  end

  return unpack(res)
end

return M
