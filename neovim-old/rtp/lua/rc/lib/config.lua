local vimfn = require 'rc.lib.vimfn'
local ac = require 'rc.lib.autocmd'
local HT = require 'rc.lib.hierarchical_table'
local msg = require 'rc.lib.msg'

local M = {}

local schema = HT.new()
local global = HT.new()
local language_local = {}
local buffer_local = {}

ac.augroup('rc__config', function(au)
  au('BufUnload', '*', function()
    local bufnr = tonumber(vimfn.expand '<abuf>')
    if bufnr then
      -- データを削除する
      buffer_local[bufnr] = nil
    end
  end)
end)

---@return (boolean, key_attr|table<string, key_attr>|nil)
local function find_key_attr_for(key)
  if not HT.is_valid_key(key) then
    error(string.format("'%s' is not a valid key", key))
  end

  local ok, attr = pcall(HT.get, schema, key)
  if ok and attr then
    return true, attr
  end

  -- ここに来るのは実際に key がどんぴしゃりで存在しない場合
  -- この場合は最寄りの親が allow_unknown_subkey であれば得られる
  local components = HT.get_components(key)
  for i = #components, 1, -1 do
    local curr_key = table.concat(vim.list_slice(components, 1, i), '.')
    ok, attr = pcall(HT.get, schema, curr_key)
    if ok and attr then
      return false, attr
    end
  end

  -- それでもないなら見つからない
  return false, nil
end

local function is_set_global_allowed(key)
  local is_exact, attr = find_key_attr_for(key)
  if is_exact then
    -- 完全マッチがあった場合はなんであれ OK
    -- もちろん中間テーブルだったら実際にはよくないが、ここはそのチェックをす
    -- るべき場所ではないので
    return true
  elseif attr then
    -- key_attr が見つかった場合に key_attr ではなくただのテーブルになっている
    -- なら、これは完全マッチは見つからなかったものの同じ親を共有する別の設定
    -- が存在するということ。例えば editor.configA があるときに editor.configB
    -- を指定すると editor までたどったときに { configA = ... } みたいなテーブ
    -- ルになる。この場合でも configB は存在しないはずだから許されない。
    if not getmetatable(attr) then
      return false
    end
    return attr.allow_unknown_subkey
  end

  -- どちらでもないなら NG
  return false
end

local function is_set_local_allowed(key)
  local is_exact, attr = find_key_attr_for(key)
  if is_exact then
    -- key_attr が見つかった場合に key_attr ではなくただのテーブルになっている
    -- なら、これは完全マッチは見つからなかったものの同じ親を共有する別の設定
    -- が存在するということ。例えば editor.configA があるときに editor.configB
    -- を指定すると editor までたどったときに { configA = ... } みたいなテーブ
    -- ルになる。この場合でも configB は存在しないはずだから許されない。
    if not getmetatable(attr) then
      return false
    end
    -- そうでない場合は is_locally_overridable に依存
    return attr.is_locally_overridable
  elseif attr then
    -- key_attr が見つかった場合は key_attr のはず (テーブルになるくらいなら
    -- exact match のはずだから)
    assert(
      getmetatable(attr).__index == M.key_attr,
      'internal error: not a key_attr'
    )
    return attr.allow_unknown_subkey and attr.is_locally_overridable
  end

  return false
end

local function is_get_allowed(key)
  local is_exact, attr = find_key_attr_for(key)
  if is_exact then
    -- 中間テーブルだとしても読む分には当然 OK なので
    return true
  elseif attr then
    -- key_attr が見つかった場合に key_attr ではなくただのテーブルになっている
    -- なら、これは完全マッチは見つからなかったものの同じ親を共有する別の設定
    -- が存在するということ。例えば editor.configA があるときに editor.configB
    -- を指定すると editor までたどったときに { configA = ... } みたいなテーブ
    -- ルになる。この場合でも configB は存在しないはずだから許されない。
    if not getmetatable(attr) then
      return false
    end
    return attr.allow_unknown_subkey
  end

  return false
end

---@class key_attr
---@field public is_locally_overridable boolean ローカルに上書き可能かどうか
---@field public allow_unknown_subkey boolean 未知のサブキーを許すかどうか
M.key_attr = {}

function M.key_attr.new()
  return setmetatable({
    locally_overridable = false,
    allow_unknown_subkey = false,
  }, { __index = M.key_attr })
end

function M.key_attr.with_locally_overridable(self, value)
  self.is_locally_overridable = value
  return self
end

function M.key_attr.with_allow_unknown_subkey(self, value)
  self.allow_unknown_subkey = value
  return self
end

---@param keys table<string, key_attr>
-- keys は許されるキーをキーとしてそのキーが守るべき制約を指定する
function M.set_schema(keys)
  for k, attr in pairs(keys) do
    schema:set(k, attr)
  end
end

---@overload fun(keyvalue: table)
---@param key string
---@param value any
function M.set_global(key, value)
  local keyvalue = type(key) == 'table' and key or { [key] = value }

  for k, v in pairs(keyvalue) do
    if not is_set_global_allowed(k) then
      msg.warn("unknown key: '%s'", k)
    end
    global:set(k, v)
  end
end

---@overload fun(language: string, keyvalue: table)
---@param language string
---@param key string
---@param value any
function M.set_language(language, key, value)
  local keyvalue = type(key) == 'table' and key or { [key] = value }

  local tbl = table.get_or_insert_with(language_local, language, HT.new)
  for k, v in pairs(keyvalue) do
    if not is_set_local_allowed(k) then
      msg.warn("unknown key: '%s'", k)
    end
    tbl:set(k, v)
  end
end

---@overload fun(bufnr: number|nil, keyvalue: table)
---@param bufnr number|nil
---@param key string
---@param value any
function M.set_buffer(bufnr, key, value)
  bufnr = bufnr or vim.fn.bufnr()
  local keyvalue = type(key) == 'table' and key or { [key] = value }

  local tbl = table.get_or_insert_with(buffer_local, bufnr, HT.new)
  for k, v in pairs(keyvalue) do
    if not is_set_local_allowed(k) then
      msg.warn("unknown key: '%s'", k)
    end
    tbl:set(k, v)
  end
end

---@param key string
---@return any
function M.get_global(key)
  if not is_get_allowed(key) then
    msg.warn("unknown key: '%s'", key)
  end

  return global:get(key)
end

---@param key string
---@param language? string
---@param bufnr? number
function M.get(key, language, bufnr)
  if not is_get_allowed(key) then
    msg.warn("unknown key: '%s'", key)
  end

  language = language or vim.opt.filetype:get()
  bufnr = bufnr or vim.fn.bufnr()

  local global_value = global:get(key)
  local language_value = language_local[language]
    and language_local[language]:get(key)
  local buffer_value = buffer_local[bufnr] and buffer_local[bufnr]:get(key)

  local res = global_value

  if language_value ~= nil then
    if type(res) == 'table' and type(language_value) == 'table' then
      res:in_place_deep_extend(language_value)
    else
      res = language_value
    end
  end

  if buffer_value ~= nil then
    if type(res) == 'table' and type(buffer_value) == 'table' then
      res:in_place_deep_extend(buffer_value)
    else
      res = buffer_value
    end
  end

  return res
end

return M
