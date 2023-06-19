-- lazy の boostrap
require('rc.lib.lazy').boostrap()

-- prelude ライブラリの読み込み
require 'rc.lib.lang.prelude'

-- 警告の有効化・無効化
require('rc.lib.msg').setup()

-- Node.JS / Deno の初期化
require('rc.lib.setup_node').ensure_node()
require('rc.lib.setup_deno').ensure_deno()

require 'rc.step.basic'
require 'rc.step.keybind'

require 'rc.step.plugin'

require 'rc.step.format'
require 'rc.step.ftplugin'
require 'rc.step.gui'
