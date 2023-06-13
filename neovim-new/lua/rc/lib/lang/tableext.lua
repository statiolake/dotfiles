local iterator = require 'rc.lib.lang.iterator'

---@return iterator
---@param method any ipairs or pairs
function table.iter(self, method)
  return iterator.new(method(self))
end

---@return iterator
---@param method any @ipairs or pairs
function table.iter_keys(self, method)
  return table.iter(self, method):map(function(k, _)
    return k
  end)
end

---@return iterator
---@param method any @ipairs or pairs
function table.iter_values(self, method)
  return table.iter(self, method):map(function(_, v)
    return v
  end)
end

function table.in_place_deep_extend(self, other)
  for key, value in pairs(other) do
    if not self[key] then
      self[key] = value
    elseif type(self[key]) == 'table' and type(value) == 'table' then
      table.in_place_deep_extend(self[key], value)
    end
  end
end

---@param self tablelib
---@param key string|number
---@param default_ctor fun(): any
function table.get_or_insert_with(self, key, default_ctor)
  self[key] = self[key] or default_ctor()
  return self[key]
end
