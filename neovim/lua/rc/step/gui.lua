local ac = require 'rc.lib.autocmd'
local env = require 'rc.lib.env'
local c = require 'rc.config'

local font
if env.is_win32 then
  font = {
    size = 12,
    enjp = nil,
    en = 'Consolas',
    jp = 'Meiryo',
  }
else
  font = {
    size = 12,
    enjp = nil,
    en = 'Hack NF',
    jp = 'M+ 1m',
  }
end

-- colorset 初期化
require('rc.lib.colorset').setup(c.colorset)

-- 基本 GUI 設定 (起動完了前) {{{
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
local has_lualine, _ = require 'lualine'
vim.opt.laststatus = has_lualine and 3 or 2

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
-- }}}

-- (lualine を使わないとき) ステータスライン更新 {{{
if not has_lualine then
  local line = ''

  -- 左
  line = line .. " %{v:lua.require'rc.lib.statusline'.mode()}"
  line = line .. ' | %f%( %m%)%( %r%)%( %w%)'
  -- 区切り
  line = line .. '%='
  -- 右
  line = line .. "| %{v:lua.require'rc.lib.statusline'.lsp_status(v:true)} "

  vim.opt.statusline = line
end
-- }}}

-- winbar {{{
-- local fnreg = require 'rc.lib.function_registry'
--
-- -- winbar に symbol line を表示する
-- if b(vim.fn.has 'nvim-0.8') then
--   local winbar = ''
--
--   -- ファイル名
--   winbar = winbar .. '%f'
--
--   -- 変更があればマークを追加する
--   local modified = c.use_icons and ' ' or '[+]'
--   winbar = winbar .. ('%{&modified ? "' .. modified .. '" : ""}')
--
--   local symbol_line_fnstr = fnreg.global_registry:register_for_vimscript(
--     function()
--       return stl.symbol_line()
--     end,
--     'symbol_line_helper'
--   )
--   winbar = winbar .. ('%{%' .. symbol_line_fnstr .. '()%}')
--
--   vim.opt.winbar = winbar
-- end
-- }}}

--- カーソル設定 {{{
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
--}}}

-- 起動完了後 {{{
ac.on_uienter(function()
  local gui = env.gui

  local function withsize(fname, specifier)
    if not specifier then
      specifier = ':h'
    end
    return fname .. specifier .. font.size
  end

  -- GUI に合わせて設定していく
  if gui == 'neovim-qt' then
    vim.cmd.GuiFont {
      withsize(font.enjp or font.en),
      bang = true,
    }
    vim.opt_global.guifontwide = font.jp
  elseif gui == 'nvui' then
    vim.opt_global.guifont = table.concat(
      pack {
        withsize(font.en),
        font.jp,
        when(env.is_win32, 'Segoe UI Emoji'),
        when(env.is_win32, 'Segoe UI Symbol'),
      },
      ','
    )
  elseif gui == 'nvy' then
    vim.opt_global.guifont = table.concat(
      pack {
        withsize(font.en),
        font.jp,
        when(env.is_win32, 'Segoe UI Emoji'),
        when(env.is_win32, 'Segoe UI Symbol'),
      },
      ','
    )
  elseif gui == 'neovide' then
    vim.opt_global.guifont = table.concat(
      pack {
        withsize(font.en),
        font.jp,
        when(env.is_win32, 'Segoe UI Emoji'),
        when(env.is_win32, 'Segoe UI Symbol'),
      },
      ','
    )
  else
    vim.opt_global.guifont = withsize(font.enjp or font.en)
    vim.opt_global.guifontwide = withsize(font.jp)
  end

  vim.opt.linespace = 4

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
end)
-- }}}
