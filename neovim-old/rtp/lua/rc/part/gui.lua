local ac = require 'rc.lib.autocmd'
local env = require 'rc.env'
local manager = require 'rc.lib.plugin_manager'
local stl = require 'rc.statusline'
local cg = get_global_config

-- 基本 GUI 設定 (起動完了前)
local function setup_gui()
  -- 起動時にイントロ画面を表示しない
  vim.opt.shortmess:append 'I'

  -- 現在行ハイライト
  vim.opt.cursorline = true

  -- 相対行番号表示
  vim.opt.relativenumber = false

  -- 行番号表示
  vim.opt.number = true

  -- 常にステータスラインを表示
  -- 新しい Neovim ではグローバルステータスラインを有効にする
  -- Note: LuaLine を使う場合はそちらでも設定する必要がある
  vim.opt.laststatus = manager.tap 'lualine' and 3 or 2

  -- シンタックスハイライトを利用する
  vim.cmd [[syntax on]]

  -- 対応する括弧を入力したときに一時的に対応をハイライトしない
  -- たいてい見づらくカーソルの位置を見失うので。
  vim.opt.showmatch = false

  -- 検索時にハイライト
  vim.opt.hlsearch = true

  -- テキストの自動折返しは基本 78 にしておく。問題が起きるようなファイルタイプ
  -- は手動で 0 に設定すべし。
  vim.opt.textwidth = 78

  -- 常に何行か残してスクロールする
  vim.opt.scrolloff = 0

  -- 折り返された行を同じインデントで表示する
  -- FIXME gq コマンドと相性が悪いみたいなのでオフにする
  vim.opt.breakindent = false

  -- 最終行で長い行を折り返したとき `@@@@` と表示しない
  vim.opt.display:append 'lastline'

  -- 常に左側にエラー・警告などのサイン用スペースを確保する
  vim.opt.signcolumn = 'yes'

  -- コマンドラインの高さ
  vim.opt.cmdheight = 2

  -- ビープしない
  vim.opt.belloff = 'all'

  -- ターミナルでも GUI カラーを利用する
  vim.opt.termguicolors = true
  vim.env.NVIM_TUI_ENABLE_TRUE_COLOR = 1

  -- 検索等の後に自動で QuickFix を起動する
  ac.augroup('rc__quickfix_cmd_post', function(au)
    au('QuickFixCmdPost', '*', 'cwindow')
  end)

  -- タイトルを表示する
  vim.opt.title = true
  vim.opt.titlestring = '%f %m %y - Neovim'
  if env.is_wsl then
    vim.opt.titlestring = vim.opt.titlestring:get() .. ' (WSL)'
  end

  -- タブや空白などを可視化する
  vim.opt.list = true
  vim.opt.listchars = {
    tab = '^-',
    extends = '>',
    precedes = '<',
    nbsp = '%',
  }

  -- ポップアップメニューを半透明にする
  vim.opt.pumblend = 0

  -- floating window を半透明にする
  vim.opt.winblend = 0

  -- インクリメンタルに置換し、結果をプレビューする
  vim.opt.inccommand = 'split'

  -- 曖昧な文字幅
  -- Neovim-qt では double にするとレイアウトが崩れる。
  vim.opt.ambiwidth = 'single'
  if vim.opt.ambiwidth:get() == 'single' then
    -- ウィンドウ区切り
    vim.opt.fillchars:append { vert = '│' }
  end
end

local function setup_gui_after()
  local gui = env.gui
  local function withsize(fname, specifier)
    if not specifier then
      specifier = ':h'
    end
    return fname .. specifier .. cg 'ui.font.size'
  end

  local fontset_maps = {
    {
      win32 = {
        withsize(cg 'ui.font.enjp.win32' or cg 'ui.font.en.win32'),
        wide = cg 'ui.font.jp.win32',
      },
      linux = {
        withsize(cg 'ui.font.enjp.linux' or cg 'ui.font.en.linux'),
        wide = cg 'ui.font.jp.linux',
      },
    },
    ['neovim-qt'] = {
      win32 = {
        function()
          vim.cmd(
            'GuiFont! '
              .. withsize(cg 'ui.font.enjp.win32' or cg 'ui.font.en.win32')
          )
        end,
        wide = cg 'ui.font.jp.win32',
      },
      linux = {
        function()
          vim.cmd(
            'GuiFont! '
              .. withsize(cg 'ui.font.enjp.linux' or cg 'ui.font.en.linux')
          )
        end,
        wide = cg 'ui.font.jp.linux',
      },
    },
    nvui = {
      win32 = {
        withsize(cg 'ui.font.en.win32'),
        cg 'ui.font.jp.win32',
        'Segoe UI Emoji',
        'Segoe UI Symbol',
      },
      linux = {
        withsize(cg 'ui.font.en.linux'),
        cg 'ui.font.jp.linux',
      },
    },
    nvy = {
      win32 = {
        withsize(cg 'ui.font.en.win32'),
        'Hack NF',
        cg 'ui.font.jp.win32',
        'Segoe UI Emoji',
        'Segoe UI Symbol',
      },
    },
    neovide = {
      win32 = {
        cg 'ui.font.en.win32',
        cg 'ui.font.jp.win32',
        'Segoe UI Emoji',
        withsize 'Segoe UI Symbol',
      },
      linux = {
        cg 'ui.font.en.linux',
        withsize(cg 'ui.font.jp.linux'),
      },
    },
  }

  -- ここからはフォントを実際に設定する処理

  local fontset = fontset_maps[gui]
  if fontset == nil then
    fontset = fontset_maps[1]
  end

  -- TODO: Mac などにも対応すべし
  fontset = (env.is_win32 or env.is_wsl) and fontset.win32 or fontset.linux
  if fontset ~= nil then
    if type(fontset) == 'function' then
      -- { win32 = function() ... end } の場合
      fontset()
    elseif type(fontset[1]) == 'function' then
      -- { win32 = { function() ... end, wide = ... } } の場合
      fontset[1]()
    else
      -- { win32 = 'fontname' } または { win32 = {'a', 'b', ... } } の場合
      local font = type(fontset) == 'string' and fontset
        or table.concat(fontset, ',')
      vim.opt.guifont = font
    end

    if fontset.wide ~= nil then
      if type(fontset.wide) == 'function' then
        fontset.wide()
      else
        vim.opt.guifontwide = fontset.wide
      end
    end
  end

  vim.opt.linespace = cg 'ui.font.linespace'

  if gui == 'neovim-qt' then
    vim.cmd [[
      GuiTabline 0
      GuiPopupmenu 0
      call GuiForeground()
    ]]
  elseif gui == 'nvui' then
    vim.cmd [[
      NvuiAnimationsEnabled 0
      NvuiTitlebarSeparator ' - '
    ]]
    if env.is_win32 then
      vim.cmd [[
        NvuiFrameless v:true
        NvuiTitlebarFontFamily Yu Gothic UI
        NvuiTitlebarFontSize 9
      ]]
    end
  elseif gui == 'neovide' then
    vim.g.neovide_cursor_animation_length = 0
    vim.g.neovide_cursor_vfx_mode = 'pixiedust'
    vim.g.neovide_remember_window_size = true
  end
end

local function setup_statusline()
  local stl = ''

  -- 左
  stl = stl .. " %{v:lua.require'rc.statusline'.mode()}"
  stl = stl .. ' | %f%( %m%)%( %r%)%( %w%)'
  -- 区切り
  stl = stl .. '%='
  -- 右
  stl = stl .. "| %{v:lua.require'rc.statusline'.lsp_status(v:true)} "

  vim.opt.statusline = stl
end

local function setup_winbar()
  local fnreg = require 'rc.lib.function_registry'

  -- winbar に symbol line を表示する
  if b(vim.fn.has 'nvim-0.8') then
    vim.opt.winbar = ''

    -- ファイル名
    vim.opt.winbar:append '%f'

    -- 変更があればマークを追加する
    local modified = cg 'ui.useIcons' and ' ' or '[+]'
    vim.opt.winbar:append('%{&modified ? "' .. modified .. '" : ""}')

    local symbol_line_fnstr = fnreg.global_registry:register_for_vimscript(
      function()
        return stl.symbol_line()
      end,
      'symbol_line_helper'
    )
    vim.opt.winbar:append('%{%' .. symbol_line_fnstr .. '()%}')
  end
end

local function setup_cursor()
  ---Convert table to guicursor string
  ---@param val table
  local function convert(val)
    require 'rc.lib.lang.tableext'
    local opts = table
      .iter(val, pairs)
      :map(function(k, v)
        return k .. ':' .. v
      end)
      :to_table()
    return table.concat(opts, ',')
  end

  -- 横線 (Horizontal bar)
  --vim.opt.guicursor = convert {
  --  ['n-v-c'] = 'block',
  --  ['o'] = 'hor50',
  --  ['i-ci'] = 'hor10',
  --  ['r-cr'] = 'hor30',
  --  ['sm'] = 'block',
  --}

  -- デフォルトカーソル形状
  vim.opt.guicursor = convert {
    ['n-v-c'] = 'block-Cursor/lCursor',
    ['ve'] = 'ver35-Cursor',
    ['o'] = 'hor50-Cursor',
    ['i-ci'] = 'ver30-Cursor/lCursor',
    ['r-cr'] = 'hor20-Cursor/lCursor',
    ['sm'] = 'block-Cursor-blinkwait175-blinkoff150-blinkon175',
  }

  -- カーソル形状変化なし
  -- vim.opt.guicursor = convert {
  --   a = 'block-Cursor/lCursor',
  -- }

  -- 点滅なし
  --vim.opt.guicursor:append({a = 'blinkon0'})
end

-- colorset 初期化
require('rc.lib.colorset').setup(cg 'ui.colorset')

-- GUI 設定
setup_gui()
setup_statusline()
-- FIXME: coc-list と相性が悪いみたいなので治るまで無効にする
-- setup_winbar()
setup_cursor()

-- GUI 設定 (起動後)
ac.on_uienter(setup_gui_after)
