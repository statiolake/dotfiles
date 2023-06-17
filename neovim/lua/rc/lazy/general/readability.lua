local k = require 'rc.lib.keybind'

return {
  {
    'bronson/vim-trailing-whitespace',
    event = 'VeryLazy',
    init = function()
      vim.g.extra_whitespace_ignored_filetypes = {
        'defx',
        'lsp-installer',
        'TelescopePrompt',
        'markdown',
        'terminal',
      }
    end,
  },
  {
    'rhysd/conflict-marker.vim',
    event = 'VeryLazy',
    init = function()
      vim.g.conflict_marker_begin = '^<<<<<<< .*$'
      vim.g.conflict_marker_end = '^>>>>>>> .*$'
    end,
  },
  {
    'mechatroner/rainbow_csv',
    ft = 'csv',
  },
  {
    'statiolake/vim-fontzoom',
    keys = {
      '<Plug>(fontzoom-larger)',
      '<Plug>(fontzoom-smaller)',
    },
    init = function()
      k.nno('g^', '<Plug>(fontzoom-larger)')
      k.nno('g-', '<Plug>(fontzoom-smaller)')
      vim.g.fontzoom_no_default_key_mappings = 1
    end,
  },
}
