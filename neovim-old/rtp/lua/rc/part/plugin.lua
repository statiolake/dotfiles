-- デフォルトプラグインの無効化
vim.g.did_install_default_menus = 1
vim.g.did_install_syntax_menu = 1
vim.g.did_indent_on = 1
vim.g.did_load_filetypes = 1
vim.g.did_load_ftplugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_man = 1
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_remote_plugins = 1
vim.g.loaded_shada_plugin = 1
vim.g.loaded_spellfile_plugin = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.skip_loading_mswin = 1

local prof = require 'rc.lib.profile'
local cg = get_global_config

-- 自作のパッケージマネージャーに設定を読み込む
local ide = cg 'editor.ide.framework'
prof.zone('register plugins: system', function()
  require 'rc.part.plugin.system'
end)
prof.zone('register plugins: general', function()
  require 'rc.part.plugin.general'
end)
prof.zone('register plugins: colorset', function()
  require 'rc.part.plugin.colorset'
end)
prof.zone('register plugins: ide', function()
  require('rc.part.plugin.' .. ide)
end)
prof.zone('register plugins: filetype', function()
  require 'rc.part.plugin.filetype'
end)

if cg 'editor.useTreesitter' then
  prof.zone('register plugins: treesitter', function()
    require 'rc.part.plugin.treesitter'
  end)
end

local manager = require 'rc.lib.plugin_manager'

-- プラグイン及び設定を読み込む
prof.zone('load plugins and settings', function()
  -- 仮にロードが失敗しても後のコマンドなどを登録するためにガードしておく
  local ok, err = pcall(manager.load)
  if not ok then
    require('rc.lib.msg').error('error while loading plugins: %s', err)
  end
end)

-- 自作の package_manager 用のコマンド
local cmd = require 'rc.lib.command'
local cmphlp = require 'rc.lib.completer_helper'

cmd.add('PlugUpdate', function(ctx)
  local args = #ctx.args > 0 and ctx.args or nil
  manager.update(args)
end, {
  nargs = '*',
  complete = cmphlp.create_completer_from_static_list(
    table.iter_keys(manager.list(), pairs):to_table()
  ),
})

cmd.add('PlugClean', function()
  manager.clean()
end)

cmd.add('PlugOpenDir', function(ctx)
  manager.open_dir(ctx.args[1])
end, {
  nargs = 1,
  complete = cmphlp.create_completer_from_static_list(
    table.iter_keys(manager.list(), pairs):to_table()
  ),
})
