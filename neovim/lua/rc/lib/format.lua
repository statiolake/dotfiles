local ac = require 'rc.lib.autocmd'
local cmd = require 'rc.lib.command'
local k = require 'rc.lib.keybind'
local vimfn = require 'rc.lib.vimfn'
local c = require 'rc.config'

local function allwinsaveview()
  local orig_winid = vim.fn.win_getid(vim.fn.winnr())
  local view = {}
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.fn.win_gettype(winid) == '' then
      -- 通常タイプのウィンドウに限る
      vim.fn.win_gotoid(winid)
      view[winid] = vim.fn.winsaveview()
    end
  end
  vim.fn.win_gotoid(orig_winid)
  return view
end

local function allwinrestview(view)
  local orig_winid = vim.fn.win_getid(vim.fn.winnr())
  for winid, state in pairs(view) do
    vim.fn.win_gotoid(winid)
    vim.fn.winrestview(state)
  end
  vim.fn.win_gotoid(orig_winid)
end

local disable_temporary = false

local function should_run()
  if disable_temporary then
    return false
  end

  return c.format_on_save
end

local function run_builtin_formatter(is_auto)
  local timeout_ms = is_auto and 2000 or 10000

  -- null-ls にこのファイルタイプ向けのソースが登録されているのなら null-ls
  -- に絞る
  local use_null_ls = false
  local ok, null_ls = pcall(require, 'null-ls')
  if ok then
    for _, source in ipairs(null_ls.get_sources()) do
      if source.filetypes[vim.opt.filetype:get()] then
        if source.methods[null_ls.methods.FORMATTING] then
          use_null_ls = true
          break
        end
      end
    end
  end

  vim.lsp.buf.format {
    async = false,
    timeout_ms = timeout_ms,
    filter = when(use_null_ls, function(client)
      return client.name == 'null-ls'
    end),
  }
end

local function run_coc_formatter(_is_auto)
  if b(vim.fn.exists '*CocAction') then
    if vimfn.expand '%:t' == 'coc-settings.json' then
      pcall(vim.fn.CocAction, 'runCommand', 'formatJson', '--sort-keys')
    end
    --pcall(vim.fn.CocAction, 'organizeImport')
    pcall(vim.fn.CocAction, 'format')
  end
end

local function run_formatter(is_auto)
  -- FIXME: もう少し一般化するべき？
  if
    vim.opt.filetype:get() ~= 'markdown'
    and b(vim.fn.exists ':FixWhitespace')
  then
    vim.cmd 'FixWhitespace'
  end

  if c.ide == 'builtin' then
    run_builtin_formatter(is_auto)
  elseif c.ide == 'coc' then
    run_coc_formatter(is_auto)
  end
end

local function run(is_auto)
  -- autocmd から実行されているときは、設定でグローバルに無効化しているときは
  -- 実行しない。
  if is_auto and not should_run() then
    return
  end

  -- すべての処理を一つの undo ブロックへまとめ、フォーマットだけ undo するこ
  -- とができるようにする。
  local view = allwinsaveview()
  vim.cmd('normal! ' .. k.t 'i <Esc>"_dl')
  vim.cmd 'undojoin'
  run_formatter(is_auto)
  allwinrestview(view)
end

local M = {}

-- <CR> 時に後続の文字に合わせてフォーマットする文字列を返す
function M.keyseq_on_cr()
  local keyseq = k.t '<CR>'

  -- この改行地点より後ろに文字がある場合は整形する
  local back_str = string.sub(vimfn.getline '.', vim.fn.col '.')
  local trimmed_back_str = string.gsub(back_str, '^%s*(.-)%s*$', '%1')
  if trimmed_back_str ~= '' then
    -- 基本は空白行を入れない
    keyseq = k.t '<CR><Esc>==I'
    for _, endpair in ipairs { ')', ']', '}', '>' } do
      if string.starts_with(trimmed_back_str, endpair) then
        -- 終わりなら空白行を入れる
        keyseq = k.t '<CR><Esc>==O'
        break
      end
    end
  end

  return keyseq
end

function M.save_without_format(save_cmd)
  disable_temporary = true
  vim.cmd(save_cmd)
  disable_temporary = false
end

-- フォーマッタを登録する
function M.setup()
  ac.augroup('rc__format_on_save', function(au)
    au('BufWritePre', '*', function()
      run(true)
    end)
  end)

  cmd.add('Format', function()
    run(false)
  end, { nargs = '0' })
end

return M
