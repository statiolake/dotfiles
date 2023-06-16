local k = require 'rc.lib.keybind'
local cmd = require 'rc.lib.command'
local env = require 'rc.lib.env'

-- Windows で <C-z> を無効化する
--
-- <C-z> をサスペンド処理する雰囲気があり、しかもそれされると身動きとれなくなっ
-- てしまうので <Nop> へ移動する。
if env.is_win32 then
  k.add({ 'i', 'n', 'v', 'o' }, '<C-z>', '<Nop>')
end

-- <F1> を <Esc> にマップする
--
-- <F1> がうるさいので...
k.add({ 'i', 'n', 'v', 'o' }, '<F1>', '<Esc>')

-- ターミナルを開くキーバインドを設定する
-- local keys = { '<C-@>', '<C-\\>' }
-- for _, key in ipairs(keys) do
--   k.nno(key, function()
--     local shell = env.shell
--     local cmd_terminal
--     if vim.fn.bufname() == '' then
--       -- 空のバッファならそこをターミナルに置き換える
--       cmd_terminal = 'terminal'
--     else
--       -- そうでないならいい感じに split してやる
--       local vsplit = require('lib.layout').preferred_split()
--       cmd_terminal = string.format('%s | terminal', vsplit)
--     end
--     vim.cmd(string.format('%s %s', cmd_terminal, shell))
--
--     -- filetype を terminal にする
--     vim.opt.filetype = 'terminal'
--   end)
-- end

-- terminal も <Esc> 二回押しで抜けられるようにしてみる
k.add('t', '<Esc><Esc>', '<C-\\><C-n>', { noremap = true })

-- 悪魔的に Insert / Select を拡張する
k.ino('<S-CR>', '<Esc>O')
k.ino('<C-CR>', '<Esc>o')
k.ino('<C-z>', k.cmd 'undo')
k.ino('<C-y>', k.cmd 'redo')
k.ino('<C-l>', '<Space><Esc>C')
k.ino('<C-Del>', '<Space><Esc>ce')

k.sno('<C-z>', '<Esc>a' .. k.cmd 'undo')
k.sno('<C-y>', '<Esc>a' .. k.cmd 'redo')

-- カーソル移動ごとに undo ポイントを作る
k.ino('<Left>', '<C-g>u<Left>')
k.ino('<Down>', '<C-g>u<Down>')
k.ino('<Up>', '<C-g>u<Up>')
k.ino('<Right>', '<C-g>u<Right>')
k.ino('<Home>', '<C-g>u<Home>')
k.ino('<End>', '<C-g>u<End>')
k.ino('<Space>', '<Space><C-g>u')

k.ino('<A-h>', '<C-g>u<Left>')
k.ino('<A-j>', '<C-g>u<Down>')
k.ino('<A-k>', '<C-g>u<Up>')
k.ino('<A-l>', '<C-g>u<Right>')
k.ino('<A-a>', '<C-g>u<Home>')
k.ino('<A-e>', '<C-g>u<End>')

-- k.ino('<Space>', '<Space><C-g>u')
-- k.ino('<A-Space>', '<Space><C-g>u')

-- <F11>, <F12> で <C-i>, <C-o>
-- AutoHotKey などで XButton1 -> F11 などの対応を付けているのが前提
k.nno('<F11>', '<C-o>')
k.nno('<F12>', '<C-i>')

-- <C-n>, <C-p> を (ループする) :cnext 系にする
local function looping(kind, dir)
  local cmd_move = kind .. dir
  local cmd_loop = kind .. (dir == 'next' and 'first' or 'last')

  return function()
    vim.cmd(
      string.format(
        'try | %s | catch | %s | catch | endtry',
        cmd_move,
        cmd_loop
      )
    )
  end
end

if vim.fn.mapcheck('<C-n>', 'n') == '' then
  k.nno('<C-n>', k.cmd 'Cnext')
  k.nno('<C-p>', k.cmd 'Cprev')
end
k.nno('<A-n>', k.cmd 'Cnext')
k.nno('<A-p>', k.cmd 'Cprev')

cmd.add('Cnext', looping('c', 'next'))
cmd.add('Cprev', looping('c', 'prev'))
cmd.add('Lnext', looping('l', 'next'))
cmd.add('Lprev', looping('l', 'prev'))

-- vim での行移動を論理行から表示行にする
--k.add({ 'n', 'x', 'o' }, 'j', 'gj', { noremap = true })
--k.add({ 'n', 'x', 'o' }, 'k', 'gk', { noremap = true })
--k.add({ 'n', 'x', 'o' }, 'gj', 'j', { noremap = true })
--k.add({ 'n', 'x', 'o' }, 'gk', 'k', { noremap = true })

-- 連続的にインデント
k.vno('>', '>gv')
k.vno('<', '<gv')

-- Y を yy にする
k.nno('Y', 'yy')

-- ウィンドウ操作を改善する
k.nno('<C-w>1', k.cmd 'only')
k.nno('<C-w>n', 'gt')
k.nno('<C-w>p', 'gT')
k.nno('<C-w>c', k.cmd 'tabnew')
k.nno('<C-w>x', k.cmd 'tabclose')

-- 選択した範囲の各行にマクロを実行する
-- https://github.com/stoeffel/.dotfiles/blob/master/vim/visual-at.vim
k.xno('@', function(first, last)
  vim.cmd(string.format(
    [[
      echo "@" .. getcmdline()
      execute ":%d,%dnormal! @" .. nr2char(getchar())
    ]],
    first,
    last
  ))
end, { range = true })

-- 選択した各行を <C-j>, <C-k> で上下に移動する
k.xno('<C-j>', ":m '>+1<CR>gv=gv")
k.xno('<C-k>', ":m '<-2<CR>gv=gv")

-- <leader>p でレジスタを変えずに選択範囲の置換をやる
k.xno('<leader>p', '"_dP')

-- <C-d>, <C-u>, n, N で画面中心をキープする
-- k.nno('<C-d>', '<C-d>zz')
-- k.nno('<C-u>', '<C-u>zz')
-- k.nno('n', 'nzzzv')
-- k.nno('N', 'Nzzzv')

-- <M-CR> でフルスクリーンを切り替える (可能な場合)
k.nno('<M-CR>', function()
  if b(vim.fn.exists '*GuiWindowFullScreen') then
    vim.fn.GuiWindowFullScreen(vim.g.GuiWindowFullScreen == 0 and 1 or 0)
  end
end)
