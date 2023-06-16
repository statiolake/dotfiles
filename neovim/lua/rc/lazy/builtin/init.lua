local ac = require 'rc.lib.autocmd'
local k = require 'rc.lib.keybind'
local vimfn = require 'rc.lib.vimfn'
local c = require 'rc.config'

-- Hack: https://github.com/neovim/neovim/pull/19677 に対応する
-- とんでもないデフォルト値を設定してくれたもんだな...
ac.augroup('rc__fix_formatexpr', function(au)
  au('LspAttach', '*', function()
    vim.opt_local.formatexpr = ''
  end)
end)

-- E303 により signature help やポップアップが表示されない問題の修正
local function disable_swap_on_vs_vim_buffer()
  ac.augroup('rc__disable_swap_on_vs_vim_buffer', function(au)
    au('BufAdd', 'VS.Vim.Buffer*', function()
      -- 追加されたバッファの番号を取得
      local bufnr =
        inspect(vim.fn.bufnr(vimfn.expand('<afile>', false, false)))
      if bufnr >= 0 then
        vim.api.nvim_buf_set_option(bufnr, 'swapfile', false)
      end
    end)
  end)
end

return {
  { import = 'rc.lazy.builtin.individual.lspconfig' },
  { import = 'rc.lazy.builtin.individual.nullls' },
  {
    'nvim-lua/lsp-status.nvim',
    config = function()
      require('lsp-status').config {
        -- Diagnostics は Lualine で表示されるのでいらない
        diagnostics = false,
        indicator_errors = c.signs.diagnostics.error,
        indicator_warnings = c.signs.diagnostics.warning,
        indicator_info = c.signs.diagnostics.info,
        indicator_hint = c.signs.diagnostics.hint,
        indicator_ok = 'OK',
        spinner_frames = {
          '.',
          'o',
          'O',
          '@',
          '*',
          '.',
          'o',
          'O',
          '@',
          '*',
        },
      }
    end,
  },
  { 'RRethy/vim-illuminate' },
  {
    'SmiteshP/nvim-navic',
    config = function()
      -- 遅延ロード
      ac.on_vim_started(function()
        require('nvim-navic').setup {
          icons = {
            File = c.use_icons and ' ' or 'FILE:',
            Module = c.use_icons and ' ' or 'MOD:',
            Namespace = c.use_icons and ' ' or 'NS:',
            Package = c.use_icons and ' ' or 'PKG:',
            Class = c.use_icons and ' ' or 'C:',
            Method = c.use_icons and ' ' or 'M:',
            Property = c.use_icons and ' ' or 'P:',
            Field = c.use_icons and ' ' or 'V:',
            Constructor = c.use_icons and ' ' or 'CTOR:',
            Enum = c.use_icons and '練' or 'E:',
            Interface = c.use_icons and '練' or 'IF:',
            Function = c.use_icons and ' ' or 'F:',
            Variable = c.use_icons and ' ' or 'V:',
            Constant = c.use_icons and ' ' or 'CONST:',
            String = c.use_icons and ' ' or 'S:',
            Number = c.use_icons and ' ' or 'I:',
            Boolean = c.use_icons and '◩ ' or 'B:',
            Array = c.use_icons and ' ' or 'A:',
            Object = c.use_icons and ' ' or 'O:',
            Key = c.use_icons and ' ' or 'K:',
            Null = c.use_icons and 'ﳠ ' or 'N:',
            EnumMember = c.use_icons and ' ' or 'EM:',
            Struct = c.use_icons and ' ' or 'C:',
            Event = c.use_icons and ' ' or 'EV:',
            Operator = c.use_icons and ' ' or 'OP:',
            TypeParameter = c.use_icons and ' ' or 'T:',
          },
        }
      end)
    end,
  },
  { import = 'rc.lazy.builtin.individual.cmp' },
  {
    'matsui54/denops-signature_help',
    dependencies = { 'denops.vim' },
    init = function()
      vim.g.signature_help_config = {
        border = c.border
          and c.border[1]
          and (c.border[1][1] or c.border[1]) ~= ' ',
        style = 'virtual',
        multiLabel = true,
      }
      require('rc.lib.colorset').register_editor_colorscheme_hook(function()
        vim.cmd [[
          hi! link SignatureHelpVirtual Comment
          hi! link LspSignatureActiveParameter Special
        ]]
      end)
      disable_swap_on_vs_vim_buffer()
    end,
    config = function()
      vim.fn['signature_help#enable']()
    end,
  },

  {
    'j-hui/fidget.nvim',
    config = function()
      require('fidget').setup {
        text = {
          spinner = {
            '.',
            'o',
            'O',
            '@',
            '*',
            '.',
            'o',
            'O',
            '@',
            '*',
          },
          done = 'OK',
        },
      }
    end,
  },

  {
    'folke/trouble.nvim',
    config = function()
      require('trouble').setup {
        icons = c.use_icons,
        fold_open = c.use_icons and '' or '~',
        fold_closed = c.use_icons and '' or '+',
        signs = c.signs.diagnostics,
      }

      k.nno('<A-m>', k.cmd 'TroubleToggle')
    end,
  },
}
