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
    'norcalli/nvim-colorizer.lua',
    -- termguicolors が設定されていないといけないらしいので遅延する
    event = 'VeryLazy',
    config = function()
      require('colorizer').setup({ '*' }, {
        RGB = true, -- #RGB
        RRGGBB = true, -- #RRGGBB
        names = true, -- Blue などの色名
        RRGGBBAA = true, -- #RRGGBBAA
        rgb_fn = true, -- CSS の rgb(), rgba()
        hsl_fn = true, -- CSS の hsl(), hsla()
        css = true, -- CSS の機能: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = true, -- CSS の関数: rgb_fn, hsl_fn
        mode = 'background', -- [foreground, background]
      })
    end,
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
