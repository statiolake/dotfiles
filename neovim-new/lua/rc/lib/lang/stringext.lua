---@param self string
---@param n number
function string.nth(self, n)
  return string.sub(self, n, n)
end

---@param self string
---@param prefix string
function string.starts_with(self, prefix)
  return string.sub(self, 1, string.len(prefix)) == prefix
end

---@param self string
---@param postfix string
function string.ends_with(self, postfix)
  return string.sub(
    self,
    string.len(self) - string.len(postfix) + 1,
    string.len(self)
  ) == postfix
end

---@param self string
function string.chars(self)
  return table.iter_values(vim.fn.split(self, '\\zs'), ipairs)
end
