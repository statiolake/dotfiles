c = {}

c.ide = 'coc'
c.format_on_save = true
c.use_treesitter = true
c.use_icons = false
c.colorset = 'alduin'
c.signs = {
  diagnostics = {
    error = c.use_icons and '' or '#',
    warning = c.use_icons and '' or '!',
    info = c.use_icons and '' or '=',
    hint = c.use_icons and '' or '>',
  },
  diff = {
    added = c.use_icons and '┃' or '+',
    change_removed = c.use_icons and '┃' or '~',
    changed = c.use_icons and '┃' or '~',
    removed = c.use_icons and '' or '_',
    top_removed = c.use_icons and '' or '‾',
  },
}

-- c.border = {
--   { '╭', 'FloatBorder' },
--   { '─', 'FloatBorder' },
--   { '╮', 'FloatBorder' },
--   { '│', 'FloatBorder' },
--   { '╯', 'FloatBorder' },
--   { '─', 'FloatBorder' },
--   { '╰', 'FloatBorder' },
--   { '│', 'FloatBorder' },
-- }
-- c.border = {
--   { '┌', 'FloatBorder' },
--   { '─', 'FloatBorder' },
--   { '┐', 'FloatBorder' },
--   { '│', 'FloatBorder' },
--   { '┘', 'FloatBorder' },
--   { '─', 'FloatBorder' },
--   { '└', 'FloatBorder' },
--   { '│', 'FloatBorder' },
-- }
-- c.border = {
--   { '+', 'FloatBorder' },
--   { '-', 'FloatBorder' },
--   { '+', 'FloatBorder' },
--   { '|', 'FloatBorder' },
--   { '+', 'FloatBorder' },
--   { '-', 'FloatBorder' },
--   { '+', 'FloatBorder' },
--   { '|', 'FloatBorder' },
-- }
c.border = {
  { ' ', 'FloatBorder' },
  { ' ', 'FloatBorder' },
  { ' ', 'FloatBorder' },
  { ' ', 'FloatBorder' },
  { ' ', 'FloatBorder' },
  { ' ', 'FloatBorder' },
  { ' ', 'FloatBorder' },
  { ' ', 'FloatBorder' },
}

-- set_global_config {
-- }

-- if b(vim.fn.executable 'zathura') then
--   set_global_config {
--     ['lsp.texlab.texlab.forwardSearch.executable'] = 'zathura',
--     ['lsp.texlab.texlab.forwardSearch.args'] = {
--       '-x',
--       string.format(
--         [[nvim --server '%s' --remote '%%{input}:%%{line}']],
--         vim.v.servername
--       ),
--       '--synctex-forward',
--       '%l:0:%f',
--       '%p',
--     },
--   }
-- end

return c
