local M = {}

local env = require 'rc.env'
local vimfn = require 'rc.lib.vimfn'

local system_path = coalesce {
  when(env.is_win32, 'node'),
  when(env.is_unix, '/usr/bin/node'),
}

function M.ensure_node()
  if vim.fn.executable(system_path) ~= 1 then
    M.setup_standalone_node()
  end
end

function M.setup_standalone_node()
  local node_base_path = env.is_win32 and '~/.dotfiles_standalone_node'
    or '~/.dotfiles_standalone_node/bin'
  node_base_path = vimfn.expand(node_base_path)
  local path_env = vim.fn.getenv 'PATH' or ''
  path_env = node_base_path .. (env.is_win32 and ';' or ':') .. path_env
  vim.fn.setenv('PATH', path_env)
end

return M
