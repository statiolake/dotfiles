-- なんか型が大変なことになっている VimScript 関数のラッパー

local M = {}

---@param expr string
---@param nosuf? boolean
---@param list? boolean
---@return string
function M.expand(expr, nosuf, list)
  nosuf = nosuf or false
  list = list or false
  ---@diagnostic disable-next-line
  return vim.fn.expand(expr, nosuf, list)
end

---@param lnum string
---@param _end string
---@return string[]
---@overload fun(lnum: string): string
function M.getline(...)
  return vim.fn.getline(...)
end

setmetatable(M, {
  __index = vim.fn,
})

return M
