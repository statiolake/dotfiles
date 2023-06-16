return {
  {
    'nvim-treesitter/nvim-treesitter',
    event = 'VeryLazy',
    dependencies = {
      'playground',
      'nvim-ts-context-commentstring',
      'nvim-yati',
      'vim-matchup',
    },
    config = function()
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
        ensure_installed = {
          'diff',
          'gitcommit',
          'lua',
          'vim',
          'rust',
          'html',
          'xml',
        },
        yati = { enable = true },
        highlight = { enable = true },
        indent = { enable = false },
        context_commentstring = { enable = true },
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
  },
  {
    'nvim-treesitter/playground',
    lazy = true,
  },
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    lazy = true,
  },
  {
    'yioneko/nvim-yati',
    lazy = true,
  },
}
