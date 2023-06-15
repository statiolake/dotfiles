local ac = require 'rc.lib.autocmd'
local k = require 'rc.lib.keybind'
local vimfn = require 'rc.lib.vimfn'

local cg = get_global_config

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
        indicator_errors = cg 'ui.signs.diagnostics.error',
        indicator_warnings = cg 'ui.signs.diagnostics.warning',
        indicator_info = cg 'ui.signs.diagnostics.info',
        indicator_hint = cg 'ui.signs.diagnostics.hint',
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
        local use_icons = get_global_config 'ui.useIcons'
        require('nvim-navic').setup {
          icons = {
            File = use_icons and ' ' or 'FILE:',
            Module = use_icons and ' ' or 'MOD:',
            Namespace = use_icons and ' ' or 'NS:',
            Package = use_icons and ' ' or 'PKG:',
            Class = use_icons and ' ' or 'C:',
            Method = use_icons and ' ' or 'M:',
            Property = use_icons and ' ' or 'P:',
            Field = use_icons and ' ' or 'V:',
            Constructor = use_icons and ' ' or 'CTOR:',
            Enum = use_icons and '練' or 'E:',
            Interface = use_icons and '練' or 'IF:',
            Function = use_icons and ' ' or 'F:',
            Variable = use_icons and ' ' or 'V:',
            Constant = use_icons and ' ' or 'CONST:',
            String = use_icons and ' ' or 'S:',
            Number = use_icons and ' ' or 'I:',
            Boolean = use_icons and '◩ ' or 'B:',
            Array = use_icons and ' ' or 'A:',
            Object = use_icons and ' ' or 'O:',
            Key = use_icons and ' ' or 'K:',
            Null = use_icons and 'ﳠ ' or 'N:',
            EnumMember = use_icons and ' ' or 'EM:',
            Struct = use_icons and ' ' or 'C:',
            Event = use_icons and ' ' or 'EV:',
            Operator = use_icons and ' ' or 'OP:',
            TypeParameter = use_icons and ' ' or 'T:',
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
      local cfg_border = cg 'ui.border'
      vim.g.signature_help_config = {
        border = cfg_border
          and cfg_border[1]
          and (cfg_border[1][1] or cfg_border[1]) ~= ' ',
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
      local use_icons = cg 'ui.useIcons'
      require('trouble').setup {
        icons = use_icons,
        fold_open = use_icons and '' or '~',
        fold_closed = use_icons and '' or '+',
        signs = (cg 'ui.signs').diagnostics,
      }

      k.nno('<A-m>', k.cmd 'TroubleToggle')
    end,
  },
}
