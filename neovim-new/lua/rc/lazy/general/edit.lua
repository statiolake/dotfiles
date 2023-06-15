local cmd = require 'rc.lib.command'
local k = require 'rc.lib.keybind'

return {
  {
    'windwp/nvim-autopairs',
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
        disable_macro = true,
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
      vim.g.closetag_xhtml_filenames = '*.xhtml,*.xml,*.xaml,*.jsx'
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
        ['typescript.tsx'] = 'jsxRegion,tsxRegion',
        ['javascript.jsx'] = 'jsxRegion',
        ['typescriptreact'] = 'jsxRegion,tsxRegion',
        ['javascriptreact'] = 'jsxRegion',
      }
      -- Shortcut for closing tags, default is '>'
      vim.g.closetag_shortcut = '>'
      -- Add > at current position without closing the current tag, default is ''
      vim.g.closetag_close_shortcut = [[\>]]
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
      { '*', mode = { 'n', 'x' }, '<Plug>(asterisk-z*)' },
      { '#', mode = { 'n', 'x' }, '<Plug>(asterisk-z#)' },
      { 'g*', mode = { 'n', 'x' }, '<Plug>(asterisk-gz*)' },
      { 'g#', mode = { 'n', 'x' }, '<Plug>(asterisk-gz#)' },
    },
    init = function()
      vim.g['asterisk#keeppos'] = 1
    end,
  },
  {
    'rlane/pounce.nvim',
    keys = {
      {
        '<Leader>w',
        mode = { 'n', 'v', 'o' },
        function()
          require('pounce').pounce()
        end,
      },
    },
  },
  {
    'numToStr/Comment.nvim',
    config = true,
  },
  {
    'kana/vim-textobj-entire',
    dependencies = { 'vim-textobj-user' },
  },
  {
    'kana/vim-textobj-indent',
    dependencies = { 'vim-textobj-user' },
  },
  {
    'kana/vim-textobj-user',
  },
  {
    'tpope/vim-surround',
  },
  {
    'statiolake/vim-evalvis',
    keys = { '<C-e>', mode = 'x', '<Plug>(evalvis-eval)' },
    init = function()
      vim.g['evalvis#language'] = 'python3'
    end,
  },
  {
    'tpope/vim-repeat',
  },
  {
    -- :s 拡張 (:S) 他
    'tpope/vim-abolish',
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
    init = function()
      vim.g.table_mode_corner = '|'
    end,
  },
}
