local ac = require 'rc.lib.autocmd'

local function retry(max_trial, interval, fn)
  local timer = vim.loop.new_timer()
  timer:start(
    0,
    interval,
    vim.schedule_wrap(function()
      -- 無限に繰り返すのは無駄なので辞める
      max_trial = max_trial - 1
      if max_trial < 0 then
        timer:stop()
      end
      if fn() then
        timer:stop()
      end
    end)
  )
end

local function setup_neovim_qt_clipboard()
  -- 準備ができていないとエラーになるので pcall() で包んでおく
  local ok, _ = pcall(vim.fn['GuiClipboard'])
  return ok
end

local function setup_gui_based_clipboard()
  -- 接続のタイミングなどあってかなり後回しにしないとだめっぽい
  ac.on_uienter(function()
    retry(20, 100, function()
      for _, ui in ipairs(vim.api.nvim_list_uis()) do
        local chan = ui.chan
        if not chan or chan == 0 then
          -- ターミナル UI っぽいので無視
        else
          local chan_info = vim.api.nvim_get_chan_info(chan)

          if chan_info.client and chan_info.client.name == 'nvim-qt' then
            -- Neovim-qt が見つかったのでクリップボードに設定
            return setup_neovim_qt_clipboard()
          end
        end
      end
    end)
  end)
end

local function setup_ccli()
  local copy = { 'ccli', 'copy' }
  local paste = { 'ccli', 'paste' }
  vim.g.clipboard = {
    name = 'ccli',
    copy = { ['+'] = copy, ['*'] = copy },
    paste = { ['+'] = paste, ['*'] = paste },
  }
end

local function setup_pbcopy()
  local copy = { 'pbcopy' }
  local paste = { 'pbpaste' }
  vim.g.clipboard = {
    name = 'pbcopy',
    copy = { ['+'] = copy, ['*'] = copy },
    paste = { ['+'] = paste, ['*'] = paste },
  }
end

local function setup_win32yank()
  -- WSL でも呼び出せるようにしたいので .exe までつけている
  local copy = { 'win32yank.exe', '-i' }
  local paste = { 'win32yank.exe', '-o', '--lf' }
  vim.g.clipboard = {
    name = 'win32yank',
    copy = { ['+'] = copy, ['*'] = copy },
    paste = { ['+'] = paste, ['*'] = paste },
  }
end

local M = {}

function M.setup()
  if vim.g.clipboard then
    return
  end

  -- まず dockerman 経由のときは ccli をフォールバック的に有効化する
  if vim.fn.getenv 'DOCKERMAN_ATTACHED' == '1' then
    setup_ccli()
  elseif b(vim.fn.executable 'win32yank') then
    setup_win32yank()
  elseif b(vim.fn.executable 'pbcopy') then
    setup_pbcopy()
  end

  -- ついでもし Neovim-qt が見つかるならそちらに上書きする
  setup_gui_based_clipboard()
end

return M
