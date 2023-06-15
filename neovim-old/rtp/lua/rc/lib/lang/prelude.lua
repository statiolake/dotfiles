local functional = require 'rc.lib.lang.functional'
_G.when, _G.pack, _G.coalesce, _G.composite =
  functional.when, functional.pack, functional.coalesce, functional.composite

local conv = require 'rc.lib.lang.conv'
_G.b = conv.to_bool

local object = require 'rc.lib.lang.object'
_G.deepcopy, _G.inspect = object.deepcopy, object.inspect

local config = require 'rc.lib.config'
_G.get_global_config, _G.get_config, _G.set_global_config, _G.set_buffer_config, _G.set_language_config =
  config.get_global,
  config.get,
  config.set_global,
  config.set_buffer,
  config.set_language

require 'rc.lib.lang.tableext'
require 'rc.lib.lang.mathext'
require 'rc.lib.lang.stringext'
