local msg = require 'rc.lib.msg'

---@class iterator
---@field gen_next fun(invariant, ctrlvar): any
---@field invariant any
---@field ctrlvar any
local iterator = {}

---@param gen_next fun(invariant, ctrlvar): any
---@param invariant any
---@param ctrlvar any
---@return iterator
function iterator.new(gen_next, invariant, ctrlvar)
  -- for .. in f do ... end は、戻り値が nil でない限り繰り返し f を呼び出して
  -- その戻り値を yield するのだが、その呼び出しでは f に引数として invariant
  -- (ループが終わるまでずっと同じ値) と ctrlvar (前回のループでの f が yield
  -- した値 (複数変値の場合は最初の値) が与えられる。
  --
  -- * invariant
  --   たとえば ipairs においてはもとの配列そのもの、のように、オリジナルのデ
  --   ータを保持するのに利用できる。もちろん、クロージャーの環境内にもたせて
  --   もいいと思う。
  --
  -- * ctrlvar
  --   たとえば ipairs においては前回のループで yield した要素のインデックスで
  --   ある。今回のループではこれ + 1 番目のアイテムを yield する、みたいな用
  --   途で使える。また iota とか range みたいな用途ではカウンターの値としてこ
  --   れ + step の値を次に yield する、みたいにして使える。
  local obj = {
    gen_next = gen_next,
    invariant = invariant,
    ctrlvar = ctrlvar,
  }
  setmetatable(obj, {
    __index = iterator,
    __call = function()
      return obj:next()
    end,
  })
  return obj
end

function iterator.empty()
  return iterator.new(function()
    return nil
  end)
end

---range is inclusive.
---@param from number
---@param to? number
---@param step? number
function iterator.range(from, to, step)
  step = step or 1
  return iterator.new(function(_, prev)
    local curr = prev + step
    if to and ((prev <= to and to < curr) or (prev >= to and to > curr)) then
      return nil
    end
    return curr
  end, nil, from - step)
end

function iterator.next(self)
  local values = { self.gen_next(self.invariant, self.ctrlvar) }
  self.ctrlvar = values[1]
  if self.ctrlvar == nil then
    return nil
  end
  return unpack(values)
end

---@param n number
function iterator.skip(self, n)
  local skipped = false
  return iterator.new(function()
    if not skipped then
      skipped = true
      for _ in iterator.range(1, n) do
        local values = self:next()
        -- if iterator returns nil while skipping, return nil immediately.
        if values == nil then
          return nil
        end
      end
    end
    return self:next()
  end)
end

---@param n number
function iterator.take(self, n)
  return iterator.new(function()
    if n > 0 then
      n = n - 1
      return self:next()
    else
      return nil
    end
  end)
end

function iterator.inspect(self, inspector)
  return self:map(function(...)
    inspector(...)
    return ...
  end)
end

function iterator.flatten(self)
  local bucket = iterator.empty()
  return iterator.new(function()
    while bucket ~= nil do
      -- もとのイテレータの要素が multi-value かもしれないのでテーブルに持つ
      local values = { bucket:next() }
      if values[1] ~= nil then
        return unpack(values)
      end
      bucket = self:next()
    end
    return nil
  end)
end

function iterator.map(self, mapper)
  return iterator.new(function()
    -- もとのイテレータの要素が multi-value かもしれないのでテーブルに持つ
    local values = { self:next() }
    if values[1] == nil then
      return nil
    end
    return mapper(unpack(values))
  end)
end

function iterator.flat_map(self, mapper)
  return self:map(mapper):flatten()
end

function iterator.filter(self, pred)
  return iterator.new(function()
    local values
    repeat
      -- もとのイテレータの要素が multi-value かもしれないのでテーブルに持つ
      values = { self:next() }
    until values[1] == nil or pred(unpack(values))
    if values[1] == nil then
      return nil
    end
    return unpack(values)
  end)
end

function iterator.filter_map(self, mapper)
  return self
    :map(function(...)
      -- もとのイテレータの要素が multi-value かもしれないのでテーブルに持つ
      return { mapper(...) }
    end)
    :filter(function(values)
      return values[1] ~= nil
    end)
    :map(function(values)
      return unpack(values)
    end)
end

function iterator.take_while(self, pred)
  return iterator.new(function()
    -- もとのイテレータの要素が multi-value かもしれないのでテーブルに持つ
    local values = { self:next() }
    if values == nil or not pred(unpack(values)) then
      return nil
    end
    return unpack(values)
  end)
end

function iterator.chunks(self, size)
  if size == 0 then
    error 'chunks: size is zero'
  end

  local iter = self:fuse()
  return iterator.new(function()
    local chunk = {}

    for _ = 1, size do
      local values = { iter:next() }
      if values[1] == nil then
        if #chunk == 0 then
          return nil
        else
          return chunk
        end
      end

      if #values == 1 then
        values = values[1]
      end
      table.insert(chunk, values)
    end

    return chunk
  end)
end

---@generic T, U
---@param self iterator
---@param init T
---@param accum fun(sum:T,value:U):T
---@return T
function iterator.fold(self, init, accum)
  local sum = init
  for values in
    self:map(function(...)
      return { ... }
    end)
  do
    sum = accum(sum, unpack(values))
  end
  return sum
end

function iterator.count(self)
  return self:fold(0, function(res, ...)
    return res + 1
  end)
end

function iterator.to_table(self)
  return self:fold({}, function(res, ...)
    local values = { ... }
    if #values == 1 then
      values = values[1]
      table.insert(res, values)
    elseif #values == 2 then
      res[values[1]] = values[2]
    else
      msg.error('to_table(): too many elements (%d)', #values)
    end
    return res
  end)
end

---Consume iterator and return nothing
---@param self iterator
function iterator.consume(self)
  self:fold(nil, function(_, _) end)
end

function iterator.fuse(self)
  local consumed = false
  return iterator.new(function()
    if consumed then
      return nil
    end
    -- もとのイテレータの要素が multi-value かもしれないのでテーブルに持つ
    local res = { self:next() }
    if res[1] == nil then
      consumed = true
    end
    return unpack(res)
  end)
end

---@param other iterator
function iterator.zip(self, other)
  local aa = self:fuse()
  local bb = other:fuse()
  return iterator.new(function()
    -- もとのイテレータの要素が multi-value かもしれないのでテーブルに持つ
    local a = { aa:next() }
    local b = { bb:next() }
    if a[1] == nil and b[1] == nil then
      return nil
    end
    return unpack(a), unpack(b)
  end)
end

---@param other iterator
function iterator.equal(self, other)
  for v in self:zip(other) do
    local a, b = unpack(v)
    if a ~= b then
      return false
    end
  end
  return true
end

---@param self iterator
---@param pred fun(...): boolean
---@return boolean @true if one of element satisfies pred.
function iterator.any(self, pred)
  return self:filter(pred):next() ~= nil
end

---@param self iterator
---@param pred fun(...): boolean
---@return boolean @true if all of element satisfies pred.
function iterator.all(self, pred)
  return not self:any(function(...)
    return not pred(...)
  end)
end

---@param self iterator
---@param other iterator
---@return iterator @new iterator producing elements two iterator in order.
function iterator.concat(self, other)
  local aa = self:fuse()
  local bb = other:fuse()
  return iterator.new(function()
    -- もとのイテレータの要素が multi-value かもしれないのでテーブルに持つ
    local a = { aa:next() }

    -- a に残っていれば OK
    if a[1] then
      return unpack(a)
    end

    -- b に残っていれば OK
    local b = { bb:next() }
    if b[1] then
      return unpack(b)
    end

    -- どちらにもなければ終了
    return nil
  end)
end

return iterator
