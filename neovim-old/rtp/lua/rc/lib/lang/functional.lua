local iterator = require 'rc.lib.lang.iterator'

local M = {}

function M.composite(f, g)
  return function(...)
    return f(g(...))
  end
end

function M.coalesce(list)
  for i = 1, #list do
    local v = list[i]
    if v ~= nil then
      return v
    end
  end
  return nil
end

function M.when(cond, value)
  if cond then
    return value
  else
    return nil
  end
end

---list から nil および要素のないエントリをスキップしたリストを返す。
function M.pack(list)
  -- Lua でテーブルの要素数を素早く得る方法はないらしい...
  --
  -- #list でいいように見えるが、実は:
  -- #{1, 2, nil, 4, unpack({}), 6}   => 6
  -- #{1, 2, 3, 4, unpack({}), 6}     => 4 (!?!?!?)
  --
  -- 実際こういう sparse なリストに対して # は undefined な挙動らしい。O(n) か
  -- けて最大値を探ることにする。
  local maximum = table
    .iter(list, pairs)
    :filter(function(v)
      return type(v) == 'number'
    end)
    :fold(0, function(max, x)
      return max < x and x or max
    end)
  -- ipairs だと最初の nil でテーブルの終わりだと誤解して消えてしまうので、そ
  -- うならないようにする。pairs であれば飛んでいてもきちんとやってくれるので
  -- よい。その代わり order は unspecified なので順序が保たれるとは限らないこ
  -- とに注意。
  return iterator
    .range(1, maximum)
    :filter(function(i)
      return list[i] ~= nil
    end)
    :map(function(i)
      return list[i]
    end)
    :to_table()
end

--- テーブルを depth_limit 段階平坦化する。
---@param list list
---@param depth_limit number?
---@param result list?
---@return list
function M.flatten(list, depth_limit, result)
  result = result or {}
  depth_limit = depth_limit or 1
  for _, v in ipairs(list) do
    if type(v) == 'table' and depth_limit > 0 then
      M.flatten(v, depth_limit - 1, result)
    else
      result[#result + 1] = v
    end
  end
  return result
end

return M
