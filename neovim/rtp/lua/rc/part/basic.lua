local k = require 'rc.lib.keybind'
local ac = require 'rc.lib.autocmd'
local vimfn = require 'rc.lib.vimfn'
local env = require 'rc.env'
local cg = get_global_config

vim.opt.fileencoding = 'utf-8'
vim.opt.fileencodings = {
  'utf-8',
  'cp932',
  'ucs-bom',
  'utf-16le',
  'utf-16be',
  'euc-jp',
}
vim.opt.undofile = false
vim.opt.ignorecase = false
vim.opt.backup = false
vim.opt.swapfile = true
vim.opt.directory = vimfn.expand(vim.fn.stdpath 'data' .. '/swap')
vim.opt.expandtab = true
vim.opt.backspace = { 'indent', 'eol', 'start' }
vim.opt.wrap = true
vim.opt.incsearch = true
vim.opt.wildmenu = true
vim.opt.wildmode = 'longest:full'
vim.opt.mouse = 'nv'
vim.opt.autochdir = false
vim.opt.autowrite = false
vim.opt.foldmethod = 'marker'
vim.opt.matchpairs = vim.opt.matchpairs + '<:>'
vim.opt.splitright = true
vim.opt.hidden = true
vim.opt.fixendofline = false

-- lazyredraw, showmode は Neovide のカーソルアニメーションとは若干相性が悪い
-- ので false とする
vim.opt.lazyredraw = false
vim.opt.showmode = false

-- <Esc> の反応速度を早める
vim.opt.ttimeoutlen = 10

-- インデント
vim.opt.autoindent = true
vim.opt.smartindent = false
vim.opt.cindent = true
vim.opt.cinkeys = { '0{', '0}', '0)', '0]', ':', '!^F', 'o', 'O', 'e' }
vim.opt.cinoptions = { '(s', 'm1' }

-- indentexpr を自動設定させないようにする → やっぱり使う
--vim.cmd[[filetype plugin on]]
--vim.cmd[[filetype indent off]]
vim.cmd [[filetype plugin indent on]]

-- Note: インデント幅は vim-sleuth により自動設定される
vim.opt.tabstop = 8
vim.opt.shiftwidth = 2

vim.g.mapleader = k.t '<Space>'
vim.g.maplocalleader = k.t '<Space>'

-- netrw の無効化
vim.g.loaded_netrwPlugin = 1

-- 'autoread' {{{
vim.opt.autoread = true
-- イベントに応じて適宜 :checktime を呼び出す
ac.augroup('rc__nvim_autoread_checktime', function(au)
  au({ 'FocusGained', 'VimResume' }, '*', function()
    vim.cmd [[checktime]]
  end)
end)
-- }}}

-- 'formatoptions': 'jcroqmB' {{{
ac.augroup('rc__formatoptions', function(au)
  au('BufEnter', '*', function()
    -- Note: skkeleton または ddc を使うときは 'c' を外す
    -- ddc も自動フォーマットがあると textwidth が近づいたとき補完を返さなくな
    -- るので。
    -- Note: やっぱり常に外す。フォーマットが自動でなくても良い気がしてきた
    -- （どうせテキストを削除したときとかに手動で gq する癖はあるので）
    vim.opt_local.formatoptions = {
      j = true,
      c = false,
      r = true,
      o = true,
      q = true,
      m = true,
      B = true,
    }
  end)
end)
-- }}}

-- 'colorcolumn': &textwidth {{{
ac.augroup('rc__set_ruler', function(au)
  local function update_colorcolumn()
    -- FIXME: どういうわけかわからないが、とりあえず autocmd OptionSet だと
    -- nvim-cmp で補完候補を選んだときに textwidth == 0 みたいな値が 3 連続で
    -- 飛んでくる。そのイベント内で textwidth を取得すると 0 になってしまうが、
    -- その後何のイベントもないまましれっと textwidth は元の値になっているので、
    -- 実際には変更されていないのではないかと思う...。いずれにせよ少し時間をず
    -- らして textwidth を更新するようにしてみる。
    vim.fn.timer_start(100, function()
      local tw = vim.opt_local.textwidth:get()
      if tw == 0 then
        vim.opt_local.colorcolumn = {}
      else
        vim.opt_local.colorcolumn = { tw }
      end
    end, { ['repeat'] = 1 })
  end
  au('BufEnter', '*', update_colorcolumn)
  au(
    'OptionSet',
    'textwidth',
    update_colorcolumn,
    { guarded_filetypes = { 'help' } }
  )
end)
-- }}}

-- 'hlsearch': !insert {{{
-- coc の pum がハイライトされてしまうので
if cg 'editor.ide.framework' == 'coc' then
  ac.augroup('rc__set_hlsearch', function(au)
    au('InsertEnter', '*', 'set nohlsearch')
    au('InsertLeave', '*', 'set hlsearch')
  end)
end
-- }}}

-- クリップボード設定
require('rc.clipboard').setup()

-- 何かと入用なのでサーバーはとりあえず開始しておく
if env.is_win32 then
  pcall(vim.fn.serverstart, [[\\.\pipe\nvimpipe]])
end
-- vimtex とかで使う
if b(vim.fn.empty(vim.v.servername)) then
  vim.fn.serverstart 'localhost:0'
end

-- dockerman attach で直接実行されたときは <C-z> を無効化する
if vim.fn.getenv 'DIRECT_NVIM' == '1' then
  k.nno('<C-z>', '<Nop>')
end

-- ログ用のフォルダがデフォルトでは存在しないみたいなので修正する
local log_dir = vim.fn.stdpath 'cache'
if not b(vim.fn.isdirectory(log_dir)) then
  vim.fn.mkdir(log_dir, 'p')
end
