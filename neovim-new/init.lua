-- lazy の boostrap
require('rc.lazy').boostrap()

-- prelude ライブラリの読み込み
require 'rc.lib.lang.prelude'

-- 警告の有効化・無効化
require('rc.lib.msg').setup()

-- Node.JS / Deno の初期化
require('rc.lib.setup_node').ensure_node()
require('rc.lib.setup_deno').ensure_deno()

-- プラグインのセットアップ
require('lazy').setup 'rc.lazy'

-- デフォルト
require 'rc.part.basic'
