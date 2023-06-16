local functional = require 'rc.lib.lang.functional'
_G.when, _G.pack, _G.coalesce, _G.composite =
  functional.when, functional.pack, functional.coalesce, functional.composite

local conv = require 'rc.lib.lang.conv'
_G.b = conv.to_bool

local object = require 'rc.lib.lang.object'
_G.deepcopy, _G.inspect = object.deepcopy, object.inspect

require 'rc.lib.lang.tableext'
require 'rc.lib.lang.mathext'
require 'rc.lib.lang.stringext'
