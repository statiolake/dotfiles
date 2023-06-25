local env = require 'rc.lib.env'
local ac = require 'rc.lib.autocmd'
local k = require 'rc.lib.keybind'

local pum = true

return {
  {
    'Shougo/ddc.vim',
    event = 'InsertEnter',
    dependencies = pack {
      'denops.vim',
      'ddc-matcher_subseq',
      'ddc-sorter_subseq',
      'ddc-source-around',
      'ddc-source-nvim-lsp',
      'ddc-buffer',
      'ddc-source-file',
      'ddc-source-omni',
      'ddc-ultisnips',
      'ddc-source-cmdline',
      'ddc-source-cmdline-history',
      'ultisnips',
      when(not pum, 'ddc-ui-native'),
      'ddc-ultisnips-expand',
      when(pum, 'ddc-ui-pum'),
    },
    init = function()
      local snip = require 'rc.lib.ultisnips_wrapper'

      vim.opt.completeopt = { 'menuone', 'noselect' }

      local function get_mode()
        return vim.fn.mode():sub(1, 1)
      end

      local function pum_visible()
        if pum then
          return b(vim.fn['pum#visible']())
        else
          return b(vim.fn.pumvisible())
        end
      end

      local function complete_info()
        if pum then
          return vim.fn['pum#complete_info']()
        else
          return vim.fn.complete_info()
        end
      end

      local function pum_selected()
        local info = complete_info()
        return b(info.pum_visible) and info.selected >= 0
      end

      local function keyseq_break_undo()
        return k.t '<C-g>u'
      end

      local function keyseq_confirm(force)
        if not force and not pum_selected() then
          return ''
        end

        if pum then
          return k.t(k.cmd 'call pum#map#confirm()')
        else
          return k.t '<C-y>'
        end
      end

      local function keyseq_cancel()
        if not pum_visible() then
          return ''
        end

        return k.t '<C-e>'
      end

      local function keyseq_close()
        if not pum_visible() then
          return ''
        end

        return pum_selected() and keyseq_confirm() or keyseq_cancel()
      end

      local function keyseq_insert_next()
        if not pum_visible() then
          return ''
        end

        if pum then
          return k.t(k.cmd 'call pum#map#insert_relative(1)')
        else
          return k.t '<C-n>'
        end
      end

      local function keyseq_insert_prev(fallback)
        if not pum_visible() then
          return fallback or ''
        end

        if pum then
          return k.t(k.cmd 'call pum#map#insert_relative(-1)')
        else
          return k.t '<C-p>'
        end
      end

      local function keyseq_tab()
        local mode = get_mode()
        if mode == 'i' and pum_visible() then
          return keyseq_insert_next()
        elseif snip.jumpable(1) then
          return snip.keyseq_jump_next(vim.fn.mode():sub(1, 1))
        end

        return k.t '<Tab>'
      end

      local function keyseq_s_tab()
        local mode = get_mode()
        if mode == 'i' and pum_visible() then
          return keyseq_insert_prev()
        elseif snip.jumpable(-1) then
          return snip.keyseq_jump_prev(mode)
        end

        return k.t '<S-Tab>'
      end

      local function register_complete_done(once)
        ac.augroup('rc__expand_lsp_snip', function(au)
          au('CompleteDone', '*', function()
            vim.api.nvim_feedkeys(keyseq_break_undo(), 'int', false)
            local completed_item = vim.v.completed_item
            vim.fn['ddc_ultisnips_expand#on_complete_done'](completed_item)
          end, { once = once })
        end)
      end

      local function register_next_snippet_expansion()
        register_complete_done(true)
      end

      local function keyseq_confirm_expand_snippet(force)
        if force or pum_selected() then
          register_next_snippet_expansion()
          return keyseq_confirm(true)
        end
        return ''
      end

      local function cr_with_autopairs()
        -- nvim-autopairs がある場合はそれをトリガーする
        local ok, autopairs = pcall(require, 'nvim-autopairs')
        return ok and autopairs.autopairs_cr() or k.t '<CR>'
      end

      local function keyseq_cr()
        if pum_selected() then
          -- <CR> ではスニペットを展開はしない
          return keyseq_confirm()
        elseif pum_visible() then
          -- キャンセルして改行を通常通り挿入する
          -- Note: これは pum.vim を使っていると意図通りに動かない
          return keyseq_close() .. cr_with_autopairs()
        end

        return cr_with_autopairs()
      end

      local function keyseq_c_cr()
        if pum_selected() then
          -- <C-CR> ではスニペットを展開する
          return keyseq_confirm_expand_snippet()
        elseif pum_visible() then
          -- 最初の候補を選択してスニペットを展開する
          -- Note: これは pum.vim を使っていると意図通りに動かない
          return keyseq_insert_next() .. keyseq_confirm_expand_snippet(true)
        end

        -- それ以外の場合は <Esc>o と同じ (keybind.lua で設定したものの復元)
        return k.t '<Esc>o'
      end

      k.ino('<C-Space>', vim.fn['ddc#map#manual_complete'], { expr = true })
      k.ino('<CR>', keyseq_cr, { expr = true })
      k.ino('<C-CR>', keyseq_c_cr, { expr = true })
      k.ino('<C-@>', keyseq_c_cr, { expr = true })
      k.ino('<Tab>', keyseq_tab, { expr = true })
      k.ino('<S-Tab>', keyseq_s_tab, { expr = true })
      k.sno('<Tab>', keyseq_tab, { expr = true })
      k.sno('<S-Tab>', keyseq_s_tab, { expr = true })
      k.ino('<C-y>', keyseq_confirm_expand_snippet, { expr = true })
      k.ino('<C-n>', keyseq_insert_next, { expr = true })
      k.ino('<C-p>', keyseq_insert_prev, { expr = true })
      k.ino('<C-e>', keyseq_cancel, { expr = true })

      -- TODO: ハードコードではなく <A-j> のもともとの機能を取得してラップする
      -- べき
      local function prev_or_up()
        if pum_visible() then
          return keyseq_insert_prev()
        end
        return k.t '<C-g>u<Up>'
      end
      local function next_or_down()
        if pum_visible() then
          return keyseq_insert_next()
        end
        return k.t '<C-g>u<Down>'
      end
      k.ino('<Down>', next_or_down, { expr = true })
      k.ino('<Up>', prev_or_up, { expr = true })
      k.ino('<A-j>', next_or_down, { expr = true })
      k.ino('<A-k>', prev_or_up, { expr = true })

      -- コマンドラインモード
      -- k.nno(':', function()
      --   k.cno('<C-Space>', vim.fn['ddc#map#manual_complete'], { expr = true })
      --   k.cno('<Tab>', function()
      --     vim.fn['pum#map#insert_relative'](1)
      --   end)
      --   k.cno('<S-Tab>', function()
      --     vim.fn['pum#map#insert_relative'](-1)
      --   end)
      --   k.cno('<C-y>', function()
      --     vim.fn['pum#map#confirm']()
      --   end)
      --   k.cno('<C-n>', function()
      --     vim.fn['pum#map#insert_relative'](1)
      --   end)
      --   k.cno('<C-p>', function()
      --     vim.fn['pum#map#insert_relative'](-1)
      --   end)
      --   k.cno('<C-e>', function()
      --     vim.fn['pum#map#cancel']()
      --   end)
      --
      --   ac.augroup('rc__ddc_cmdline_completion', function(au)
      --     au('User', 'DDCCmdlineLeave', function()
      --       k.cun '<C-Space>'
      --       k.cun '<Tab>'
      --       k.cun '<S-Tab>'
      --       k.cun '<C-y>'
      --       k.cun '<C-n>'
      --       k.cun '<C-p>'
      --       k.cun '<C-e>'
      --     end, { once = true })
      --   end)
      --
      --   require('lazy').load { plugins = { 'ddc.vim' } }
      --   vim.fn['ddc#enable_cmdline_completion']()
      --
      --   return ':'
      -- end, { expr = true, silent = false })
    end,
    config = function()
      local ddc_patch_global = vim.fn['ddc#custom#patch_global']
      local ddc_patch_filetype = vim.fn['ddc#custom#patch_filetype']
      local function ddc_get_global(path)
        local options = vim.fn['ddc#custom#get_global']()
        local curr = options
        for _, p in ipairs(vim.split(path, '%.')) do
          curr = curr[p] or {}
        end
        return curr
      end

      local function basic_sources_and(additional_source)
        local important_sources = {}

        -- それ以外の汎用ソースは基本的に LSP 以下なので非優先
        local fallback_sources = {
          'file',
          'ultisnips',
          'buffer',
        }

        -- あとは組み合わせる操作
        --
        -- 先にあるものほど優先されるっぽい
        local function iter(s)
          return table.iter_values(s, ipairs)
        end
        return iter(important_sources)
          :concat(iter(additional_source))
          :concat(iter(fallback_sources))
          :to_table()
      end

      ddc_patch_global { -- {{{
        sources = basic_sources_and { 'nvim-lsp' },
        sourceParams = {
          ale = { cleanResultsWhitespace = true },
          file = { mode = 'win32' },
        },
        sourceOptions = {
          _ = {
            matchers = { 'matcher_subseq' },
            sorters = { 'sorter_subseq' },
            ignoreCase = true,
            maxKeywordLength = 60,
            minAutoCompleteLength = 1,
            dup = 'keep',
          },
          around = {
            mark = 'A',
            minKeywordLength = 5,
          },
          buffer = {
            mark = 'B',
            minKeywordLength = 5,
          },
          file = {
            mark = 'F',
            forceCompletionPattern = env.is_win32 and [[[^<]/\\]]
              or [[[^<]/]],
          },
          necovim = { mark = 'V' },
          ['nvim-lsp'] = {
            mark = 'L',
            forceCompletionPattern = [[\.]],
          },
          omni = { mark = 'O' },
        },

        -- 最後に source 関係なく並べ替える
        --postFilters = { 'sorter_subseq' },
      } -- }}}

      ddc_patch_filetype({ 'toml' }, { -- {{{
        sources = basic_sources_and { 'necovim' },
        sourceOptions = {
          ['necovim'] = { forceCompletionPattern = [[(\S\.|:)]] },
        },
      }) -- }}}

      ddc_patch_filetype({ 'rust', 'cpp' }, { -- {{{
        sourceOptions = {
          ['nvim-lsp'] = { forceCompletionPattern = [[(\.|::)]] },
        },
      }) -- }}}

      ddc_patch_filetype({ 'lua' }, { -- {{{
        sourceOptions = {
          ['nvim-lsp'] = { forceCompletionPattern = [[(\.|:)]] },
        },
      }) -- }}}

      ddc_patch_filetype({ 'dosbatch', 'ps1', 'autohotkey', 'registry' }, { -- {{{
        sourceOptions = {
          file = {
            forceCompletionPattern = [[\\]],
          },
        },
        sourceParams = {
          file = {
            mode = 'win32',
          },
        },
      }) -- }}}

      if b(vim.fn.exists 'vimtex#re#deoplete') then -- {{{
        ddc_patch_filetype({ 'tex' }, {
          sources = basic_sources_and { 'omni' },
          sourceOptions = {
            omni = {
              forceCompletionPattern = vim.g['vimtex#re#deoplete'],
            },
          },
          sourceParams = {
            omni = {
              omnifunc = 'vimtex#complete#omnifunc',
            },
          },
        })
      end -- }}}

      ddc_patch_global('ui', pum and 'pum' or 'native')

      vim.fn['ddc#enable']()

      -- マクロ記録を開始したら ddc の候補を表示しない
      ac.augroup('rc__ddc_no_trigger_when_macro_recording', function(au)
        local old_minAutoCompleteLength = nil
        au('RecordingEnter', '*', function()
          old_minAutoCompleteLength =
            ddc_get_global 'sourceOptions._.minAutoCompleteLength'
          ddc_patch_global {
            sourceOptions = {
              _ = {
                minAutoCompleteLength = 999,
              },
            },
          }
        end)
        au('RecordingLeave', '*', function()
          if old_minAutoCompleteLength then
            ddc_patch_global {
              sourceOptions = {
                _ = {
                  minAutoCompleteLength = old_minAutoCompleteLength,
                },
              },
            }
          end
          old_minAutoCompleteLength = nil
        end)
      end)

      -- コマンドライン補完を有効にする
      ddc_patch_global {
        autoCompleteEvents = {
          'InsertEnter',
          'TextChangedI',
          'TextChangedP',
          'CmdlineChanged',
        },
        cmdlineSources = {
          [':'] = { 'cmdline', 'cmdline-history', 'around' },
        },
      }
    end,
  },
  { 'Shougo/ddc-ui-native', lazy = true },
  { 'Shougo/ddc-ui-pum', dependencies = { 'pum.vim' }, lazy = true },
  {
    'Shougo/pum.vim',
    lazy = true,
    config = function()
      vim.fn['pum#set_option']('padding', true)
    end,
  },
  { 'Shougo/ddc-matcher_head', lazy = true },
  { 'statiolake/ddc-matcher_subseq', lazy = true },
  { 'statiolake/ddc-sorter_subseq', lazy = true },
  { 'statiolake/ddc-filter_remove_lsp_text', lazy = true },
  { 'Shougo/ddc-source-around', lazy = true },
  { 'Shougo/ddc-source-nvim-lsp', lazy = true },
  { 'matsui54/ddc-buffer', lazy = true },
  { 'LumaKernel/ddc-source-file', lazy = true },
  { 'tani/ddc-path', lazy = true },
  { 'Shougo/ddc-source-omni', lazy = true },
  { 'matsui54/ddc-ultisnips', lazy = true },
  { 'statiolake/ddc-ultisnips-expand', lazy = true },
  { 'Shougo/ddc-source-cmdline', lazy = true },
  { 'Shougo/ddc-source-cmdline-history', lazy = true },
}
