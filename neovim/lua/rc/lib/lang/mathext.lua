---Clamp value between min and max. If min > max, min is returned.
---@param value number @Target value.
---@param min number @Minimum acceptable value.
---@param max number @Maximum acceptable value.
function math.clamp(value, min, max)
  return math.max(min, math.min(value, max))
end
