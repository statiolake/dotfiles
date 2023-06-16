local msg = require 'rc.lib.msg'
local ac = require 'rc.lib.autocmd'
local c = require 'rc.config'

local M = {}

function M.setup()
  if c.ide == 'coc' then
    -- 特に何もしない
    -- (coc-extension-auto-installer で初回起動時自動インストール)
    vim.cmd [[quitall!]]
  elseif c.ide == 'builtin' then
    ac.on_vimenter(function()
      local tools = {
        'lua-language-server',
        'stylua',
        'rust-analyzer',
        'gopls',
        'pyright',
        'prettier',
        'typescript-language-server',
        'deno',
        'rustfmt',
        'goimports',
        'isort',
        'black',
      }
      for _, tool in ipairs(tools) do
        msg.info('installing %s...', tool)
        pcall(vim.cmd, 'MasonInstall ' .. tool)
      end
      vim.cmd [[quitall!]]
    end)
  end
end

return M
