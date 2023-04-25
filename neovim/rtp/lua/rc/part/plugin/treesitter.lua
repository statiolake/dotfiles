local manager = require 'rc.lib.plugin_manager'
local use, use_as_deps = manager.use, manager.use_as_deps

use {
  'nvim-treesitter/nvim-treesitter',
  depends = {
    'playground',
    'nvim-ts-context-commentstring',
    'nvim-ts-autotag',
    'vim-matchup',
  },
  after_load = function()
    require('nvim-treesitter.parsers').list.xml = {
      install_info = {
        url = 'https://github.com/Trivernis/tree-sitter-xml',
        files = { 'src/parser.c' },
        generate_requires_npm = true,
        branch = 'main',
      },
      filetype = 'xml',
    }

    require('nvim-treesitter.configs').setup {
      ensure_installed = { 'lua', 'vim', 'rust', 'html', 'xml' },
      highlight = { enable = true },
      indent = { enable = true },
      context_commentstring = { enable = true },
      autotag = {
        enable = true,
      },
    }

    -- fold
    local fold_filetypes = { 'json' }
    local ac = require 'rc.lib.autocmd'
    ac.augroup('rc__treesitter_foldexpr', function(au)
      au('FileType', table.concat(fold_filetypes, ','), function()
        vim.opt_local.foldmethod = 'expr'
        vim.opt_local.foldexpr = 'nvim_treesitter#foldexpr()'
      end)
    end)
  end,
}

use_as_deps 'nvim-treesitter/playground'

use_as_deps 'yioneko/nvim-yati'

use_as_deps 'JoosepAlviste/nvim-ts-context-commentstring'

use_as_deps 'windwp/nvim-ts-autotag'

-- LSP による navic がある
-- use {
--   'SmiteshP/nvim-gps',
--   depends = { 'nvim-treesitter' },
--   after_load = function()
--     require('nvim-gps').setup {
--       disable_icons = not get_global_config('ui.useIcons'),
--
--       icons = {
--         ['class-name'] = ' ', -- Classes and class-like objects
--         ['function-name'] = ' ', -- Functions
--         ['method-name'] = ' ', -- Methods (functions inside class-like objects)
--         ['container-name'] = ' ', -- Containers (example: lua tables)
--         ['tag-name'] = ' ', -- Tags (example: html tags)
--       },
--
--       languages = {
--         ['json'] = {
--           icons = {
--             ['array-name'] = ' ',
--             ['object-name'] = ' ',
--             ['null-name'] = '[] ',
--             ['boolean-name'] = 'ﰰﰴ ',
--             ['number-name'] = '# ',
--             ['string-name'] = ' ',
--           },
--         },
--         ['latex'] = {
--           icons = {
--             ['title-name'] = '# ',
--             ['label-name'] = ' ',
--           },
--         },
--         ['norg'] = {
--           icons = {
--             ['title-name'] = ' ',
--           },
--         },
--         ['toml'] = {
--           icons = {
--             ['table-name'] = ' ',
--             ['array-name'] = ' ',
--             ['boolean-name'] = 'ﰰﰴ ',
--             ['date-name'] = ' ',
--             ['date-time-name'] = ' ',
--             ['float-name'] = ' ',
--             ['inline-table-name'] = ' ',
--             ['integer-name'] = '# ',
--             ['string-name'] = ' ',
--             ['time-name'] = ' ',
--           },
--         },
--         ['verilog'] = {
--           icons = {
--             ['module-name'] = ' ',
--           },
--         },
--         ['yaml'] = {
--           icons = {
--             ['mapping-name'] = ' ',
--             ['sequence-name'] = ' ',
--             ['null-name'] = '[] ',
--             ['boolean-name'] = 'ﰰﰴ ',
--             ['integer-name'] = '# ',
--             ['float-name'] = ' ',
--             ['string-name'] = ' ',
--           },
--         },
--         ['yang'] = {
--           icons = {
--             ['module-name'] = ' ',
--             ['augment-path'] = ' ',
--             ['container-name'] = ' ',
--             ['grouping-name'] = ' ',
--             ['typedef-name'] = ' ',
--             ['identity-name'] = ' ',
--             ['list-name'] = '﬘ ',
--             ['leaf-list-name'] = ' ',
--             ['leaf-name'] = ' ',
--             ['action-name'] = ' ',
--           },
--         },
--
--         -- lang = false で無効化できる
--         -- ["bash"] = false, -- disables nvim-gps for bash
--         -- ["go"] = false,   -- disables nvim-gps for golang
--
--         -- デフォルト設定を上書きすることも
--         -- ['ruby'] = {
--         --   separator = '|',
--         --   icons = {
--         --     ['function-name'] = '',
--         --     ['tag-name'] = '',
--         --     ['class-name'] = '::',
--         --     ['method-name'] = '#',
--         --   },
--         -- },
--       },
--
--       separator = ' > ',
--
--       -- limit for amount of context shown
--       -- 0 means no limit
--       depth = 0,
--
--       -- indicator used when context hits depth limit
--       depth_limit_indicator = '..',
--     }
--   end,
-- }
