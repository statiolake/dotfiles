local c = require 'rc.config'
local vimfn = require 'rc.lib.vimfn'

-- プラグインのセットアップ
local local_dir = vimfn.expand '~/dev/github'
local possible_subdir = vimfn.expand(local_dir .. '/statiolake')
if b(vim.fn.isdirectory(possible_subdir)) then
  local_dir = possible_subdir
end

require('lazy').setup('rc.lazy', {
  dev = {
    path = local_dir,
  },
  ui = {
    icons = {
      cmd = c.use_icons and ' ' or 'cmd:',
      config = c.use_icons and '' or 'cfg:',
      event = c.use_icons and '' or 'evt:',
      ft = c.use_icons and ' ' or ' ft:',
      init = c.use_icons and ' ' or 'int:',
      import = c.use_icons and ' ' or 'imp:',
      keys = c.use_icons and ' ' or 'key:',
      lazy = c.use_icons and '󰒲 ' or 'lzy:',
      loaded = c.use_icons and '●' or ' lo:',
      not_loaded = c.use_icons and '○' or 'nlo:',
      plugin = c.use_icons and ' ' or 'plg:',
      runtime = c.use_icons and ' ' or 'rtm:',
      source = c.use_icons and ' ' or 'src:',
      start = c.use_icons and '' or 'sta:',
      task = c.use_icons and '✔ ' or 'tsk:',
      list = {
        c.use_icons and '●' or '*',
        c.use_icons and '➜' or '>',
        c.use_icons and '★' or '!',
        c.use_icons and '‒' or '-',
      },
    },
  },
})
