local p = require 'rc.lib.plugin_manager'

p.use 'hello/world'
p.use {
  'hello/world2',
  depends = { 'world3' },
  before_load = function()
    error 'hello'
  end,
  after_load = function()
    error 'world2'
  end,
}
p.use { 'hello/world3', depends = { 'world' } }
p.use { 'hello/world4', opt_depends = { 'world', 'world3' } }
p.use {
  'hello/world5',
  depends = { 'world3', 'world4' },
  opt_depends = { 'world6' },
}
p.use { 'hello/world6', as_deps = true }
p.use { 'hello/world7', as_deps = true }

p.load()
