local M = {}

function M.create_completer_from_static_list(list)
  return function(leading, _entire, _cursor)
    return table.iter_values(list, ipairs)
      :filter(function(v)
        return v:starts_with(leading)
      end)
      :to_table()
  end
end

return M
