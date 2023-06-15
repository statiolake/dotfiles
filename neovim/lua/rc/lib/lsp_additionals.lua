local msg = require 'rc.lib.msg'
local ac = require 'rc.lib.autocmd'
local cg = get_global_config

local M = {}

function M.setup()
  local ide = cg 'editor.ide.framework'
  if ide == 'coc' then
    -- 特に何もしない
    -- (coc-extension-auto-installer で初回起動時自動インストール)
    vim.cmd [[quitall!]]
  elseif ide == 'builtin' then
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
