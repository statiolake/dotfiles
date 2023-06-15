local manager = require 'rc.lib.plugin_manager'
local use, use_as_deps = manager.use, manager.use_as_deps
local vimfn = require 'rc.lib.vimfn'

-- Lua 読み込みの高速化
use {
  'lewis6991/impatient.nvim',
  simple = true,
}

use {
  'k-takata/minpac',
  simple = true,
}

-- 単体で起動時に plenary.profile を使うことがあるので as_deps としない
use {
  'nvim-lua/plenary.nvim',
  simple = true,
}

use_as_deps 'nvim-lua/popup.nvim'

-- use {
--   'rcarriga/nvim-notify',
--   after_load = function()
--     vim.notify = require 'notify'
--     -- local warn_offset_encodings_once = false
--     -- vim.notify = function(m, ...)
--     --   -- null-ls と一緒に使うとこの警告が出て、かなりしつこいので、一回だけに
--     --   -- 制限する
--     --   local ignore =
--     --     'warning: multiple different client offset_encodings detected for buffer, this is not supported yet'
--     --   if m == ignore then
--     --     if warn_offset_encodings_once then
--     --       return
--     --     end
--     --     warn_offset_encodings_once = true
--     --   end
--     --   require 'notify'(m, ...)
--     -- end
--   end,
-- }

use_as_deps 'kyazdani42/nvim-web-devicons'

use_as_deps 'ryanoasis/vim-devicons'

use_as_deps 'rktjmp/lush.nvim'

use_as_deps {
  kind = manager.helper.local_if_exists,
  url = 'vim-denops/denops.vim',
  path = '~/dev/github/denops.vim',
}
