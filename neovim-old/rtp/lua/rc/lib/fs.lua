local M = {}

function M.is_path_under_dir(path, dir)
  dir = vim.fs.normalize(vim.fn.fnamemodify(dir, ':p'))
  path = vim.fs.normalize(vim.fn.fnamemodify(path, ':p'))
  return string.sub(path, 1, string.len(dir)) == dir
end

function M.is_under_cwd(path)
  return M.is_path_under_dir(path, vim.fn.getcwd())
end

function M.is_not_under_cwd(path)
  return not M.is_under_cwd(path)
end

return M
