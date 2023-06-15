---@class hierarchical_table
local hierarchical_table = {}

local function is_ht(table)
  if type(table) ~= 'table' then
    return false
  end
  local mt = getmetatable(table)
  return mt.__index and mt.__index == hierarchical_table
end

function hierarchical_table.new()
  return setmetatable({}, { __index = hierarchical_table })
end

function hierarchical_table.get_components(key)
  return vim.split(key, '%.')
end

function hierarchical_table.is_valid_key(key)
  return key ~= ''
    and not string.starts_with(key, '.')
    and not string.ends_with(key, '.')
    and not string.find(key, '%.%.')
end

---@param key string
---@param value any
function hierarchical_table.set(self, key, value)
  if not hierarchical_table.is_valid_key(key) then
    error(string.format("'%s' is not a valid key", key))
  end

  local components = hierarchical_table.get_components(key)
  local curr = self
  for i, c in ipairs(components) do
    if i == #components then
      -- 最後のコンポーネントなので値を代入したい
      if is_ht(curr[c]) then
        -- hierarchical_table なら他の設定の中間コンポーネントなのでエラーとす
        -- る
        error(string.format("error: path '%s' is a hierarchical table", key))
      end

      curr[c] = value
    else
      -- 中間コンポーネントなのでテーブルを置きたい
      if type(curr[c]) == 'nil' then
        curr[c] = hierarchical_table.new()
      end

      if not is_ht(curr[c]) then
        -- すでに table でもない値が入っているのはまずい
        local curr_key = table.concat(vim.list_slice(components, 1, i), '.')
        error(
          string.format(
            "error: path '%s' already has a value: %s",
            curr_key,
            curr[c]
          )
        )
      end

      curr = curr[c]
    end
  end
end

---@param key string
---@return any
function hierarchical_table.get(self, key)
  if not hierarchical_table.is_valid_key(key) then
    error(string.format("'%s' is not a valid key", key))
  end

  local components = hierarchical_table.get_components(key)
  local curr = self
  for i, c in ipairs(components) do
    if type(curr) == 'nil' then
      return nil
    end

    if i ~= #components and not is_ht(curr) then
      -- 中間コンポーネントなのにテーブルでないのは困る
      local curr_key = table.concat(vim.list_slice(components, 1, i), '.')
      error(
        string.format("error: key '%s' is not a hierarchical table", curr_key)
      )
    end

    curr = curr[c]
  end

  return curr
end

return hierarchical_table
