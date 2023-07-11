local ac = require 'rc.lib.autocmd'
local k = require 'rc.lib.keybind'
local vimfn = require 'rc.lib.vimfn'
local c = require 'rc.config'
local colorset = require 'rc.lib.colorset'
local cmd = require 'rc.lib.command'
local env = require 'rc.lib.env'

local completion = 'cmp'

if c.ide ~= 'builtin' then
  return {}
end

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
  { import = 'rc.lazy.ide.builtin.individual.lspconfig' },
  { import = 'rc.lazy.ide.builtin.individual.nullls' },
  {
    'nvim-lua/lsp-status.nvim',
    lazy = true,
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
        status_symbol = 'LSP',
      }
    end,
  },
  {
    'RRethy/vim-illuminate',
    lazy = true,
  },
  {
    'SmiteshP/nvim-navic',
    lazy = true,
    opts = {
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
    },
  },
  { import = 'rc.lazy.ide.builtin.individual.' .. completion },
  {
    'matsui54/denops-signature_help',
    dependencies = { 'denops.vim' },
    lazy = true,
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
    tag = 'legacy',
    lazy = true,
    opts = {
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
    },
  },
  {
    'folke/trouble.nvim',
    cmd = 'TroubleToggle',
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
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'popup.nvim',
      'plenary.nvim',
      'telescope-ui-select.nvim',
    },
    cmd = 'Telescope',
    init = function()
      k.nno('<C-e>', k.cmd 'Telescope find_files')
      k.nno('<C-f>', k.cmd 'Telescope live_grep')
      k.nno('<C-q>', k.cmd 'Telescope buffers')
      k.nno('<C-s>', k.cmd 'Telescope resume')

      -- デフォルトのハイライト色を設定する
      colorset.register_editor_colorscheme_hook(function()
        vim.cmd [[
        hi! link TelescopeBorder FloatBorder
        hi! link TelescopeNormal NormalFloat
      ]]
      end)
    end,
    config = function()
      -- リザルト画面が fold されてしまう問題を修正
      -- https://github.com/nvim-telescope/telescope.nvim/issues/991
      ac.augroup('rc__telescope_fix_fold', function(au)
        au('FileType', 'TelescopeResults', function()
          vim.opt_local.foldenable = false
        end)
      end)
      local function extract(bc)
        -- border は { char, highlight } のリストということもある
        return bc[1] or bc
      end
      local borderchars = {
        extract(c.border[2]),
        extract(c.border[4]),
        extract(c.border[6]),
        extract(c.border[8]),
        extract(c.border[1]),
        extract(c.border[3]),
        extract(c.border[5]),
        extract(c.border[7]),
      }
      local telescope = require 'telescope'
      telescope.setup {
        defaults = {
          mappings = {
            i = {
              -- skkeleton の有効化と重複するので無効化しておく
              ['<C-j>'] = false,
            },
          },
          borderchars = borderchars,
        },
      }
      telescope.load_extension 'ui-select'
    end,
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
    lazy = true,
  },
  {
    'nvim-pack/nvim-spectre',
    dependencies = { 'plenary.nvim' },
    cmd = 'Spectre',
    init = function()
      cmd.add('Spectre', function()
        require('spectre').open()
      end)
      k.nno('<A-f>', k.cmd 'Spectre')
    end,
    config = true,
  },
  {
    'lewis6991/gitsigns.nvim',
    dependencies = { 'plenary.nvim' },
    event = 'VeryLazy',
    opts = {
      signs = {
        add = {
          hl = 'GitSignsAdd',
          text = c.use_icons and '┃' or '+',
          numhl = 'GitSignsAddNr',
          linehl = 'GitSignsAddLn',
        },
        change = {
          hl = 'GitSignsChange',
          text = c.use_icons and '┃' or '~',
          numhl = 'GitSignsChangeNr',
          linehl = 'GitSignsChangeLn',
        },
        delete = {
          hl = 'GitSignsDelete',
          text = c.use_icons and '' or '_',
          numhl = 'GitSignsDeleteNr',
          linehl = 'GitSignsDeleteLn',
        },
        topdelete = {
          hl = 'GitSignsDelete',
          text = c.use_icons and '' or '‾',
          numhl = 'GitSignsDeleteNr',
          linehl = 'GitSignsDeleteLn',
        },
        changedelete = {
          hl = 'GitSignsChange',
          text = c.use_icons and '┃' or '~',
          numhl = 'GitSignsChangeNr',
          linehl = 'GitSignsChangeLn',
        },
        untracked = {
          hl = 'GitSignsAdd',
          text = c.use_icons and '┃' or '+',
          numhl = 'GitSignsAddNr',
          linehl = 'GitSignsAddLn',
        },
      },
      current_line_blame = true,
      on_attach = function(bufnr)
        local _ = bufnr

        k.n(
          ']c',
          "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'",
          { expr = true }
        )
        k.n(
          '[c',
          "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'",
          { expr = true }
        )

        -- テキストオブジェクト
        k.add({ 'o', 'x' }, 'ih', k.cmd 'Gitsigns select_hunk')
      end,
      diff_opts = {
        internal = true,
      },
    },
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
    'SirVer/ultisnips',
    dependencies = { 'vim-snippets' },
    lazy = true,
    init = function()
      vim.g.UltiSnipsSnippetStorageDirectoryForUltiSnipsEdit =
        env.path_under_config 'ultisnips'
      vim.g.UltiSnipsSnippetDirectories = { 'ultisnips' }

      vim.g.UltiSnipsEditSplit = 'context'

      -- マッピングは補完エンジン側でやる
      vim.g.UltiSnipsExpandTrigger = '<NUL>'
      vim.g.UltiSnipsJumpForwardTrigger = '<NUL>'
      vim.g.UltiSnipsJumpBackwardTrigger = '<NUL>'
      vim.g.UltiSnipsRemoveSelectModeMappings = 0
    end,
    config = function()
      ac.on_vimenter(function()
        vim.cmd [[autocmd! UltiSnips_AutoTrigger]]
      end)
    end,
  },
  { 'honza/vim-snippets', lazy = true },
}
