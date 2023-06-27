local cmd = require 'rc.lib.command'
local k = require 'rc.lib.keybind'

return {
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    init = function()
      k.i('<S-Space>', '<Space>')
    end,
    config = function()
      local autopairs = require 'nvim-autopairs'
      autopairs.setup {
        fast_wrap = { map = '<M-w>' },
        disable_filetype = {
          'TelescopePrompt',
          'ddu-ff-filter',
          'vim',
        },
        disable_in_macro = true,
        disable_in_visualblock = true,
        map_cr = false,
      }

      local Rule = require 'nvim-autopairs.rule'
      local cond = require 'nvim-autopairs.conds'
      -- `(|)` でスペースキーを押したときに `( | )` にする {{{
      local brackets = { { '(', ')' }, { '[', ']' }, { '{', '}' } }
      autopairs.add_rules {
        Rule(' ', ' ')
          :with_pair(function(opts)
            local pair = opts.line:sub(opts.col - 1, opts.col)
            return vim.tbl_contains({
              brackets[1][1] .. brackets[1][2],
              brackets[2][1] .. brackets[2][2],
              brackets[3][1] .. brackets[3][2],
            }, pair)
          end)
          :with_move(cond.none())
          :with_cr(cond.none())
          :with_del(function(opts)
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local context = opts.line:sub(col - 1, col + 2)
            return vim.tbl_contains({
              brackets[1][1] .. '  ' .. brackets[1][2],
              brackets[2][1] .. '  ' .. brackets[2][2],
              brackets[3][1] .. '  ' .. brackets[3][2],
            }, context)
          end),
      }
      for _, bracket in pairs(brackets) do
        Rule('', ' ' .. bracket[2])
          :with_pair(cond.none())
          :with_move(function(opts)
            return opts.char == bracket[2]
          end)
          :with_cr(cond.none())
          :with_del(cond.none())
          :use_key(bracket[2])
      end
      -- }}}
    end,
  },
  {
    'tpope/vim-endwise',
  },
  {
    'alvan/vim-closetag',
    init = function()
      -- filenames like *.xml, *.html, *.xhtml, ...
      -- These are the file extensions where this plugin is enabled.
      vim.g.closetag_filenames =
        '*.html,*.xhtml,*.phtml,*.xaml,*.xml,*.jsx,*.tsx'
      -- filenames like *.xml, *.xhtml, ...
      -- This will make the list of non-closing tags self-closing in the
      -- specified files.
      vim.g.closetag_xhtml_filenames = '*.xhtml,*.xml,*.xaml,*.jsx,*.tsx'
      -- filetypes like xml, html, xhtml, ...
      -- These are the file types where this plugin is enabled.
      vim.g.closetag_filetypes =
        'html,htmldjango,xhtml,phtml,xml,javascriptreact,typescriptreact'
      -- filetypes like xml, xhtml, ...
      -- This will make the list of non-closing tags self-closing in the
      -- specified files.
      vim.g.closetag_xhtml_filetypes =
        'xhtml,xml,javascriptreact,typescriptreact'
      -- integer value [0|1]
      -- This will make the list of non-closing tags case-sensitive
      -- (e.g. `<Link>` will be closed while `<link>` won't.)
      vim.g.closetag_emptyTags_caseSensitive = 1
      -- dict
      -- Disables auto-close if not in a "valid" region (based on filetype)
      vim.g.closetag_regions = {
        ['typescript.tsx'] = '',
        ['javascript.jsx'] = '',
        ['typescriptreact'] = '',
        ['javascriptreact'] = '',
      }
      -- Shortcut for closing tags, default is '>'
      vim.g.closetag_shortcut = '>'
      -- Add > at current position without closing the current tag, default is ''
      vim.g.closetag_close_shortcut = [[\>]]
    end,
  },
  {
    'mattn/emmet-vim',
    event = 'VeryLazy',
    init = function()
      vim.g.user_emmet_leader_key = '<C-k>'
      k.i('<C-k><C-k>', '<Plug>(emmet-expand-abbr)')
    end,
  },
  {
    'andymass/vim-matchup',
    init = function()
      vim.g.matchup_matchpref = {
        html = {
          tagnameonly = 1,
        },
        xml = {
          tagnameonly = 1,
        },
      }
      vim.g.matchup_matchparen_enabled = 1
    end,
  },
  {
    'haya14busa/vim-asterisk',
    keys = {
      { '<Plug>(asterisk-z*)', mode = { 'n', 'x' } },
      { '<Plug>(asterisk-z#)', mode = { 'n', 'x' } },
      { '<Plug>(asterisk-gz*)', mode = { 'n', 'x' } },
      { '<Plug>(asterisk-gz#)', mode = { 'n', 'x' } },
    },
    init = function()
      k.nx('*', '<Plug>(asterisk-z*)')
      k.nx('#', '<Plug>(asterisk-z#)')
      k.nx('g*', '<Plug>(asterisk-gz*)')
      k.nx('g#', '<Plug>(asterisk-gz#)')
      vim.g['asterisk#keeppos'] = 1
    end,
  },
  {
    'rlane/pounce.nvim',
    lazy = true,
    init = function()
      k.nvono('<Leader>w', function()
        require('pounce').pounce()
      end)
    end,
  },
  {
    'numToStr/Comment.nvim',
    event = 'VeryLazy',
    config = true,
  },
  {
    'kana/vim-textobj-entire',
    event = 'VeryLazy',
    dependencies = { 'vim-textobj-user' },
  },
  {
    'kana/vim-textobj-indent',
    event = 'VeryLazy',
    dependencies = { 'vim-textobj-user' },
  },
  {
    'kana/vim-textobj-user',
    event = 'VeryLazy',
  },
  {
    'tpope/vim-surround',
    event = 'VeryLazy',
  },
  {
    'statiolake/vim-evalvis',
    keys = { '<Plug>(evalvis-eval)' },
    init = function()
      k.x('<C-e>', '<Plug>(evalvis-eval)')
      vim.g['evalvis#language'] = 'python3'
    end,
  },
  {
    'tpope/vim-repeat',
    event = 'VeryLazy',
  },
  {
    -- :s 拡張 (:S) 他
    'tpope/vim-abolish',
    cmd = {
      'S',
      'ToSnakeCase',
      'ToUpperCase',
      'ToDashCase',
      'ToDotCase',
      'ToPascalCase',
      'ToCamelCase',
    },
    init = function()
      local function feed(keys)
        return function()
          vim.api.nvim_feedkeys(k.t(keys), '', false)
        end
      end
      cmd.add('ToSnakeCase', feed 'crs')
      cmd.add('ToUpperCase', feed 'cru')
      cmd.add('ToDashCase', feed 'cr-')
      cmd.add('ToDotCase', feed 'cr.')
      cmd.add('ToPascalCase', feed 'crm')
      cmd.add('ToCamelCase', feed 'crc')
    end,
  },
  {
    'dhruvasagar/vim-table-mode',
    cmd = {
      'TableModeDisable',
      'TableModeEnable',
      'TableModeRealign',
      'TableModeToggle',
    },
    init = function()
      vim.g.table_mode_corner = '|'
    end,
  },
}
