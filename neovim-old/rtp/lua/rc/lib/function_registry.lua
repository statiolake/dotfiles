local iterator = require 'rc.lib.lang.iterator'

---@class FunctionRegistry
---@field require_path string
---@field var_name string
---@field __registry table
local FunctionRegistry = {}

---@return FunctionRegistry
function FunctionRegistry.new(require_path, var_name)
  local obj = {
    require_path = require_path,
    var_name = var_name,
    __registry = {},
  }
  setmetatable(obj, { __index = FunctionRegistry })
  return obj
end

function FunctionRegistry.find_name(self, base)
  return iterator
    .range(1)
    :map(function(index)
      return string.format('%s%d', base, index)
    end)
    :filter(function(name)
      return self.__registry[name] == nil
    end)
    :next()
end

---@param func fun(): any
---@param basename? string
function FunctionRegistry:register_for_vimscript(func, basename)
  local prefix = string.format(
    "v:lua.require'%s'.%s.__registry.",
    self.require_path,
    self.var_name
  )
  local fnid = self:register(func, basename)
  return prefix .. fnid
end

---@param func fun()
---@param basename? string
---@return string
function FunctionRegistry:register(func, basename)
  local fnid = self:find_name(basename or 'anon')
  self.__registry[fnid] = func
  return fnid
end

---@param fnid string
---@return function|nil
function FunctionRegistry:get_by_name(fnid)
  return self.__registry[fnid]
end

FunctionRegistry.global_registry =
  FunctionRegistry.new('rc.lib.function_registry', 'global_registry')

return FunctionRegistry
