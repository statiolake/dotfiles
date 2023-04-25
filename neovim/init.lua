-- プロファイリング
local enable_profile = false

-- expand() の型アノテーションたぶん間違ってるので...
local function expand(path)
  ---@diagnostic disable-next-line: param-type-mismatch
  return vim.fn.expand(path, nil, nil)
end

-- 他ファイルの rtp を追加する
vim.opt.runtimepath:append(expand(vim.fn.stdpath 'config' .. '/rtp'))

-- prelude ライブラリの読み込み
require 'rc.lib.lang.prelude'

-- 起動警告の有効化・無効化
local ok, rc_disable_msg =
  pcall(vim.fn.str2nr, vim.fn.getenv 'NVIM_RC_DISABLE_MSG')

vim.g.rc_disable_msg = ok and rc_disable_msg ~= 0

-- プロファイリングの準備
local prof = require 'rc.lib.profile'
if enable_profile then
  prof.start(expand '~/nvim_startup_profile.log')
else
  -- Lua の読み込みの高速化
  ok, _ = pcall(require, 'impatient')
  if not ok then
    require('rc.lib.msg').note 'impatient unavailable: startup may be slower'
  end
end

prof.zone('Setup Node.JS / Deno', function()
  -- Node.JS / Deno の初期化
  require('rc.lib.setup_node').ensure_node()
  require('rc.lib.setup_deno').ensure_deno()
end)

prof.zone('load part: config', function()
  require 'rc.part.config_schema'
  require 'rc.part.config'
end)
prof.zone('load part: basic', function()
  require 'rc.part.basic'
end)
prof.zone('load part: keybind', function()
  require 'rc.part.keybind'
end)
prof.zone('load part: plugin', function()
  require 'rc.part.plugin'
end)
prof.zone('load part: format', function()
  require 'rc.part.format'
end)
prof.zone('load part: gui', function()
  require 'rc.part.gui'
end)
prof.zone('load part: ftplugin', function()
  require 'rc.part.ftplugin'
end)

-- プロファイリングの終了
if enable_profile then
  prof.stop()
end
