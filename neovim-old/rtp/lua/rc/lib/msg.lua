local M = {}

M.Severity = {
  NOTE = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

--- 表示する最小の重大度
M.severity_filter = M.Severity.INFO

function M.msg(severity, format, ...)
  if vim.g.rc_disable_msg then
    return
  end

  if severity < M.severity_filter then
    return
  end

  local tag, hl = '???', nil
  if severity == M.Severity.NOTE then
    tag = 'note'
  elseif severity == M.Severity.INFO then
    tag = 'info'
  elseif severity == M.Severity.WARN then
    tag, hl = 'warn', 'WarningMsg'
  elseif severity == M.Severity.ERROR then
    tag, hl = 'error', 'ErrorMsg'
  end

  local chunk = { string.format('%s: %s\n', tag, string.format(format, ...)) }
  if hl then
    table.insert(chunk, hl)
  end

  vim.api.nvim_echo({ chunk }, true, {})
end

function M.error(format, ...)
  M.msg(M.Severity.ERROR, format, ...)
end

function M.info(format, ...)
  M.msg(M.Severity.INFO, format, ...)
end

function M.warn(format, ...)
  M.msg(M.Severity.WARN, format, ...)
end

function M.note(format, ...)
  M.msg(M.Severity.NOTE, format, ...)
end

return M
