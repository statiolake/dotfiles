local ac = require 'rc.lib.autocmd'
local env = require 'rc.lib.env'
local vimfn = require 'rc.lib.vimfn'
local k = require 'rc.lib.keybind'

local function skk_large_dictionary()
  local jisyo_cands = {
    env.path_under_data 'SKK-JISYO.L',
    '/usr/share/skk/SKK-JISYO.L',
  }
  for _, jisyo in ipairs(jisyo_cands) do
    if vim.fn.filereadable(jisyo) ~= 0 then
      return jisyo
    end
  end
  return '(skk large dictionary not found)'
end

local function skk_user_dictionary()
  local on_dropbox = vimfn.expand '~/Dropbox/.skkeleton'
  local on_home = vimfn.expand '~/.skkeleton'
  if vim.fn.filereadable(on_dropbox) ~= 0 then
    return on_dropbox
  else
    return on_home
  end
end

return {
  {
    'vim-skk/skkeleton',
    dependencies = { 'denops.vim' },
    keys = { '<Plug>(skkeleton-enable)' },
    init = function()
      k.i('<C-j>', '<Plug>(skkeleton-enable)')
      k.c('<C-j>', '<Plug>(skkeleton-enable)')

      ac.augroup('rc__skkeleton_init', function(au)
        au('User', 'skkeleton-initialize-pre', function()
          vim.fn['skkeleton#register_kanatable']('rom', {
            ['v,'] = { ',', '' },
            ['v.'] = { '.', '' },
          })
          vim.fn['skkeleton#register_keymap']('input', '<C-j>', 'kakutei')
          vim.fn['skkeleton#config'] {
            ['markerHenkan'] = '@',
            ['markerHenkanSelect'] = '*',
            ['globalJisyo'] = skk_large_dictionary(),
            ['userJisyo'] = skk_user_dictionary(),
          }
        end)
      end)
    end,
  },
}
