local M = {}

function M.opened_node_project()
  local util = require 'lspconfig.util'
  local node_root_dir = util.root_pattern('node_modules', 'package.json')
  local fname = vim.api.nvim_buf_get_name(0)
  if not fname or fname == '' then
    fname = vim.fn.getcwd()
  end
  fname = util.path.sanitize(fname)
  return node_root_dir(fname) ~= nil
end

return M
