local M = {}

local env = require 'rc.lib.env'
local vimfn = require 'rc.lib.vimfn'

local system_path = coalesce {
  when(env.is_win32, vimfn.expand [[$USERPROFILE\scoop\shims\deno.exe]]),
  when(env.is_unix, '/usr/bin/deno'),
}

function M.ensure_deno()
  if vim.fn.executable(system_path) ~= 1 then
    M.setup_standalone_deno()
  end
end

function M.setup_standalone_deno()
  local deno_base_path = vimfn.expand '~/.dotfiles_standalone_deno'
  local path_env = vim.fn.getenv 'PATH' or ''
  path_env = deno_base_path .. (env.is_win32 and ';' or ':') .. path_env
  vim.fn.setenv('PATH', path_env)
end

return M
