local M = {}

function M.confirm()
  local bufnr = vim.api.nvim_get_current_buf()

  local entry = vim.v.completed_item
  if not entry or not entry.user_data or not entry.user_data.lspitem then
    return
  end
  local item = vim.fn.json_decode(entry.user_data.lspitem)

  local textEdit = deepcopy(item.textEdit)
  if not textEdit then
    return
  end

  -- Remove completed word
  local end_row, end_col = unpack(
    vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())
  )

  local end_ = {
    line = end_row - 1,
    character = vim.fn.strchars(
      string.sub(vim.api.nvim_get_current_line(), 0, end_col)
    ),
  }

  local start = {
    line = end_.line,
    character = end_.character - vim.fn.strchars(entry.word or ''),
  }

  vim.lsp.util.apply_text_edits({
    {
      range = {
        start = start,
        ['end'] = end_,
      },
      newText = '',
    },
  }, bufnr, 'utf-16')

  print(vim.inspect(textEdit))
  local snip = textEdit.newText
  textEdit.newText = ''
  vim.lsp.util.apply_text_edits({ textEdit }, bufnr, 'utf-16')
  require('luasnip').lsp_expand(snip)

  -- apply additionalTextEdits
  if #item.additionalTextEdits > 0 then
    vim.lsp.util.apply_text_edits(item.additionalTextEdits, bufnr, 'utf-16')
  end
end

return M
