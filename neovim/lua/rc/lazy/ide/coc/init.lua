local ac = require 'rc.lib.autocmd'
local cmd = require 'rc.lib.command'
local k = require 'rc.lib.keybind'
local msg = require 'rc.lib.msg'
local colorset = require 'rc.lib.colorset'
local vimfn = require 'rc.lib.vimfn'
local c = require 'rc.config'

if c.ide ~= 'coc' then
  return {}
end

return {
  {
    'neoclide/coc.nvim',
    branch = 'release',
    dependencies = {
      'coc-list-vim-select',
    },
    event = 'VeryLazy',
    init = function()
      -- node は実行できるように設定してあるはず
      if vim.fn.executable 'node' == 0 then
        msg.warn 'Path for NodeJS is not correctly set'
        return
      end

      -- カーソル下ハイライトのタイミングを早めるため updatetime を調整する
      vim.opt.updatetime = 500

      -- セマンティックハイライトを設定する
      colorset.register_editor_colorscheme_hook(function()
        vim.cmd [[
        hi! link CocSemNamespace Namespace
        hi! link CocSemClass Class
        hi! link CocSemFunction Function
        hi! link CocSemMember Function
        hi! link CocSemMemberVariable Variable
        hi! link CocSemEnum Enum
        hi! link CocSemEnumMember EnumMember
        hi! link CocSemInterface Interface
        hi! link CocSemStruct Struct
        hi! link CocSemType Type
        hi! link CocSemTypeParameter TypeParameter
        hi! link CocSemParameter Parameter
        hi! link CocSemVariable Variable
        hi! link CocSemProperty Property
        hi! link CocSemEvent Event
        hi! link CocSemMethod Method
        hi! link CocSemLabel Label
        hi! link CocSemRegexp Regexp
        hi! link CocSemComment Comment
        hi! link CocSemEnumConstant EnumMember
        hi! link CocSemMacro Macro
        hi! link CocSemTypeAlias Type
        hi! link CocSemAttribute Type
        hi! link CocSemLifetime Special
        hi! link CocSemBuiltinType Type

        hi! link CocSemBrace Operator
        hi! link CocSemKeyword Keyword
        hi! link CocSemOperator Operator
        hi! link CocSemParenthesis Operator
        hi! link CocSemSemicolon Operator
      ]]
      end)

      -- 補完メニューの選択したエントリの色を設定する
      colorset.register_editor_colorscheme_hook(function()
        vim.cmd [[hi! link CocMenuSel PmenuSel]]
      end)

      -- Notification の色を設定する
      colorset.register_editor_colorscheme_hook(function()
        vim.cmd [[hi! link CocNotificationButton Underlined]]
      end)

      -- Inlay Hints の色を設定する
      colorset.register_editor_colorscheme_hook(function()
        vim.cmd [[hi! link CocInlayHint NonText]]
      end)

      -- キーバインドを設定する
      local function check_back_space()
        local curr_win = vim.api.nvim_get_current_win()
        local _, col = unpack(vim.api.nvim_win_get_cursor(curr_win))
        return col == 0
          or vim.api.nvim_get_current_line():nth(col):match '%s' ~= nil
      end

      local function check_back_alphanumeric()
        local curr_win = vim.api.nvim_get_current_win()
        local _, col = unpack(vim.api.nvim_win_get_cursor(curr_win))
        local curr_line = vim.api.nvim_get_current_line()
        return curr_line ~= 0 and curr_line:nth(col):match '%w' ~= nil
      end

      local function keyseq_break_undo()
        return k.t '<C-g>u'
      end

      local function is_empty_line()
        return vim.api.nvim_get_current_line() == ''
      end

      local function is_whitespace_line()
        return vim.api.nvim_get_current_line():match '%S' == nil
      end

      local function is_pum_visible()
        return b(vim.fn['coc#pum#visible']())
      end

      local function is_pum_selected()
        return is_pum_visible() and vim.fn['coc#pum#info']().index >= 0
      end

      local function keyseq_refresh()
        return k.t '<C-r>=coc#refresh()<CR>'
      end

      local function keyseq_confirm()
        return k.t '<C-r>=coc#pum#confirm()<CR>'
      end

      local function keyseq_close()
        return k.t '<C-r>=coc#pum#close()<CR>'
      end

      local function keyseq_select_next()
        local break_undo = is_pum_selected() and '' or keyseq_break_undo()
        return break_undo .. k.t '<C-r>=coc#pum#next(1)<CR>'
      end

      local function keyseq_select_prev()
        local break_undo = is_pum_selected() and '' or keyseq_break_undo()
        return break_undo .. k.t '<C-r>=coc#pum#prev(1)<CR>'
      end

      local function keyseq_select_confirm()
        if is_pum_selected() then
          -- スニペット展開前にもう一回 undo ポイントを作っておく
          return keyseq_break_undo() .. keyseq_confirm()
        else
          -- スニペット展開前にもう一回 undo ポイントを作っておく
          return keyseq_select_next()
            .. keyseq_break_undo()
            .. keyseq_confirm()
        end
      end

      local function keyseq_jump_next()
        return k.t '<C-r>=coc#snippet#next()<CR>'
      end

      local function keyseq_jump_prev()
        return k.t '<C-r>=coc#snippet#prev()<CR>'
      end

      local function keyseq_expand_jump()
        local coc_request =
          "coc#rpc#request('doKeymap', ['snippets-expand-jump', ''])"
        return k.t('<C-r>=' .. coc_request .. '<CR>')
      end

      local function is_jumpable()
        return vim.fn['coc#jumpable']()
      end

      local function keyseq_i_arrow_down()
        if is_pum_visible() then
          return keyseq_select_next()
        else
          return k.t '<C-g>u<Down>'
        end
      end

      local function keyseq_i_arrow_up()
        if is_pum_visible() then
          return keyseq_select_prev()
        else
          return k.t '<C-g>u<Up>'
        end
      end

      k.ino('<C-Space>', vim.fn['coc#refresh'], { expr = true })
      k.ino('<Tab>', function()
        if is_pum_visible() then
          local break_undo = is_pum_selected() and '' or keyseq_break_undo()
          return break_undo .. keyseq_select_confirm()
        elseif is_jumpable() then
          return keyseq_jump_next()
        elseif is_empty_line() then
          return k.t '<Esc>S'
        elseif is_whitespace_line() then
          return k.t '<C-t>'
        end
        return keyseq_refresh()
      end, { expr = true })
      k.ino('<S-Tab>', function()
        if is_jumpable() then
          return keyseq_jump_prev()
        elseif is_whitespace_line() then
          return k.t '<C-d>'
        end
        return ''
      end, { expr = true })
      k.sno('<Tab>', vim.fn['coc#snippet#next'])
      k.sno('<S-Tab>', vim.fn['coc#snippet#prev'])

      k.ino('<CR>', function()
        if is_pum_selected() then
          return keyseq_break_undo() .. keyseq_confirm()
        else
          local keys = ''

          -- 改行前に undo ポイントを作成しておく (一つの undo が大きくなりすぎな
          -- いように)
          keys = keys .. keyseq_break_undo()

          -- 補完が開いているときはとりあえず補完を閉じる
          keys = keys .. (is_pum_visible() and keyseq_close() or '')

          -- <CR> を送信
          keys = keys .. k.t '<CR>'

          -- coc#on_enter() を動作させる
          keys = keys .. k.t '<C-r>=coc#on_enter()<CR>'

          return keys
        end
      end, { expr = true })

      k.ino('<A-j>', keyseq_i_arrow_down, { expr = true })
      k.ino('<A-k>', keyseq_i_arrow_up, { expr = true })
      k.ino('<Down>', keyseq_i_arrow_down, { expr = true })
      k.ino('<Up>', keyseq_i_arrow_up, { expr = true })
      k.ino('<C-n>', keyseq_select_next, { expr = true })
      k.ino('<C-p>', keyseq_select_prev, { expr = true })
      k.ino('<C-k>', function()
        return keyseq_break_undo() .. keyseq_select_confirm()
      end, { expr = true })
      k.ino('<C-e>', keyseq_close, { expr = true })

      k.n('<C-p>', '<Plug>(coc-diagnostic-prev)')
      k.n('<C-n>', '<Plug>(coc-diagnostic-next)')
      k.n('gd', '<Plug>(coc-diagnostic-info)')

      k.n('gR', '<Plug>(coc-rename)')
      k.n('gh', k.cmd "call CocActionAsync('doHover')")
      k.n('g;', '<Plug>(coc-float-jump)')
      k.n('g,', '<Plug>(coc-codelens-action)')
      k.v('g.', '<Plug>(coc-codeaction-selected)')
      k.i('<A-i>', k.cmd 'call CocActionAsync("showSignatureHelp")')

      -- アウトライン
      k.n('<C-t>', function()
        local winid = vim.fn['coc#window#find']('cocViewId', 'OUTLINE')
        if winid == -1 then
          vim.fn.CocActionAsync('showOutline', 1)
        else
          vim.fn['coc#window#close'](winid)
        end
      end)

      -- CocSearch
      k.nno('<A-f>', ':<C-u>CocSearch ', { silent = false })

      -- coc-explorer
      --k.n('<C-b>', k.cmd 'CocCommand explorer')

      -- -- coc-git
      k.n('[c', '<Plug>(coc-git-prevchunk)')
      k.n(']c', '<Plug>(coc-git-nextchunk)')
      k.n('[x', '<Plug>(coc-git-prevconflict)')
      k.n(']x', '<Plug>(coc-git-nextconflict)')
      k.n('<Leader>co', '<Plug>(coc-git-keepcurrent)')
      k.n('<Leader>ct', '<Plug>(coc-git-keepincoming)')
      k.n('<Leader>cb', '<Plug>(coc-git-keepboth)')

      k.n('go', '<Plug>(coc-definition)')
      k.n('<C-LeftMouse>', '<LeftMouse><Plug>(coc-definition)')
      k.n('gy', '<Plug>(coc-type-definition)')
      k.n('gI', '<Plug>(coc-implementation)')
      k.n('gr', '<Plug>(coc-references)')
      k.n('g.', '<Plug>(coc-codeaction-cursor)')

      -- リスト
      k.n('<A-:>', k.cmd 'CocCommand')
      k.n('g:', k.cmd 'CocCommand')
      k.n('<C-s>', k.cmd 'CocListResume')
      k.n('<A-n>', k.cmd 'CocNext')
      k.n('<A-p>', k.cmd 'CocPrev')

      k.n('<C-e>', k.cmd 'CocList files')
      k.n('<C-f>', k.cmd 'CocList grep')
      k.n('<C-q>', k.cmd 'CocList buffers')
      k.n('<A-w>', k.cmd 'CocList symbols')
      k.n('gw', k.cmd 'CocList symbols')
      k.n('<A-d>', k.cmd 'CocList diagnostics')
      k.n('gp', k.cmd 'CocList diagnostics')
      k.n('<A-l>', k.cmd 'CocList lists')

      vim.g.coc_snippet_prev = '<NUL>'
      vim.g.coc_snippet_next = '<NUL>'

      -- コマンドを追加する
      -- `:CocFormat` でバッファをフォーマットする
      cmd.add('CocFormat', function()
        vim.fn.CocActionAsync 'format'
      end, { nargs = '0' })

      -- `:CocFold` でバッファを折りたたむ
      cmd.add('CocFold', function(ctx)
        vim.fn.CocActionAsync('fold', unpack(ctx.args))
      end)

      -- `:CocOrganizeImport` でインポートを整理する
      cmd.add('CocOrganizeImport', function()
        vim.fn.CocActionAsync 'organizeImport'
      end, { nargs = '0' })

      vim.g.coc_global_extensions =
        { '@statiolake/coc-extension-auto-installer' }

      -- coc のデータディレクトリを変更する (Vim とかぶりたくないので)
      vim.g.coc_data_home = vimfn.expand(vim.fn.stdpath 'data' .. '/coc')

      vim.g.coc_notify_interval = 1000

      -- 全ての coc extensions を :CocUninstall するコマンドも用意する
      cmd.add('CocUninstallAll', function()
        local ids = table
          .iter_values(vim.fn.CocAction 'extensionStats', ipairs)
          :filter(function(v)
            return not v.isLocal
          end)
          :map(function(v)
            return v.id
          end)

        for id in ids do
          vim.fn.CocAction('uninstallExtension', id)
        end

        vim.api.nvim_echo({ { 'uninstall completed.' } }, true, {})
      end)
    end,
    config = function()
      -- autocmd を登録するようなやつはロードされてから実行する。そうしないと
      -- coc.nvim 自体がまだインストールされていないときに VimEnter で coc の関
      -- 数を呼び出そうとしてエラーになってしまう。
      local coc_config = vim.fn['coc#config']
      local coc_get_config = vim.fn['coc#util#get_config']

      -- sign を設定する
      local signs_diags = c.signs.diagnostics
      coc_config('diagnostic.errorSign', signs_diags.error)
      coc_config('diagnostic.warningSign', signs_diags.warning)
      coc_config('diagnostic.infoSign', signs_diags.info)
      coc_config('diagnostic.hintSign', signs_diags.hint)
      coc_config('lightbulb.text', {
        default = signs_diags.hint,
        quickfix = signs_diags.info,
      })
      coc_config('git.addedSign.text', c.signs.diff.added)
      coc_config('git.changeRemovedSign.text', c.signs.diff.change_removed)
      coc_config('git.changedSign.text', c.signs.diff.changed)
      coc_config('git.removedSign.text', c.signs.diff.removed)
      coc_config('git.topRemovedSign.text', c.signs.diff.top_removed)

      -- Hover などの基本的な autocmd を設定する
      ac.augroup('rc__coc_basic', function(au)
        -- リクエストに応じてステータスラインを再描画する
        au('User', 'CocStatusChange', function()
          vim.cmd 'redrawstatus'
        end)
        -- カーソル下のシンボルをハイライトする
        au('CursorHold', '*', function()
          pcall(vim.fn.CocActionAsync, 'highlight')
        end)
        -- 挿入モードで Signature Help を表示する
        --au('CursorHoldI', '*', function()
        --  pcall(vim.fn.CocActionAsync, 'showSignatureHelp')
        --end)
        -- スニペットをジャンプしたときに Signature Help を更新する
        au('User', 'CocJumpPlaceholder', function()
          pcall(vim.fn.CocActionAsync, 'showSignatureHelp')
        end)
      end)

      -- マシン固有の設定ファイルを設定する
      local function machine_local_setting_path()
        local filename = 'coc-machine-settings.json'
        local home = vim.fn['coc#util#get_config_home']()
        if vim.fn.isdirectory(home) == 0 then
          msg.warn 'coc config home not found; skipping machine config'
          return nil
        end
        return string.format('%s/%s', home, filename)
      end

      local function open_machine_specific_coc_config()
        local path = machine_local_setting_path()
        if not path then
          return
        end
        vim.cmd('edit ' .. path)
      end

      local function apply_machine_specific_coc_config()
        local path = machine_local_setting_path()
        if not path then
          return
        end
        if vim.fn.filereadable(path) == 0 then
          return
        end

        local ok, contents =
          pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(path), '\n'))
        if not ok then
          msg.warn 'failed to parse machine specific coc config'
          return
        end

        for key, value in pairs(contents) do
          -- coc#config(key, value) はもし value それ自体が table であ
          -- って、かつその table のキーにドットが含まれたときに壊れる。例:
          --   coc#config('Lua.workspace.library', {'/home/.config': true})
          -- は次のように (誤って) 解釈される。
          --   { 'Lua': { 'workspace': { 'library': {
          --     { '/home/': { 'config': true } },
          --   } } } }
          -- TODO: ちゃんとした表現方法を探す
          coc_config(key, value)
        end
      end

      cmd.add(
        'CocMachineConfig',
        open_machine_specific_coc_config,
        { nargs = '0' }
      )

      ac.augroup('rc__machine_specific_coc_config', function(au)
        au('VimEnter', '*', apply_machine_specific_coc_config)
      end)

      -- マクロ実行中は autoTrigger を無効にする
      ac.augroup('rc__coc_no_trigger_when_macro_recording', function(au)
        local old_autotrigger = nil
        au('RecordingEnter', '*', function()
          old_autotrigger = coc_get_config('suggest').autoTrigger
          coc_config('suggest.autoTrigger', 'none')
          pcall(vim.fn.CocAction, 'deactivateExtension', 'coc-pairs')
        end)
        au('RecordingLeave', '*', function()
          if old_autotrigger then
            coc_config('suggest.autoTrigger', old_autotrigger)
          end
          pcall(vim.fn.CocAction, 'activeExtension', 'coc-pairs')
        end)
      end)
    end,
  },
  {
    'statiolake/coc-list-vim-select',
    event = 'VeryLazy',
    config = function()
      vim.ui.select = require('coc_list_vim_select').start
    end,
  },
}
