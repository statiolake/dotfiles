local has = composite(b, vim.fn.has)
local executable = composite(b, vim.fn.executable)
local exists = composite(b, vim.fn.exists)
local expand = require('rc.lib.vimfn').expand

local M = {}

local getters = {}

setmetatable(M, {
  __index = function(_, key)
    local getter = getters[key]
    if getter then
      local ans = getter()
      M[key] = ans
      return ans
    end
    return nil
  end,
})

function getters.is_win32()
  return has 'win32'
end

function getters.is_unix()
  return has 'unix'
end

function getters.is_wsl()
  return M.is_unix and vim.fn.stridx(vim.fn.system 'uname -a', 'WSL2') >= 0
end

function getters.shell()
  if M.is_win32 and executable 'rsh.exe' then
    return 'rsh.exe'
  end

  if M.is_win32 and executable 'nyagos.exe' then
    return 'nyagos.exe'
  end

  if M.is_win32 then
    return 'cmd.exe'
  end

  if executable '/usr/bin/zsh' then
    return '/usr/bin/zsh'
  end

  local shellenv = vim.fn.getenv 'SHELL'
  if shellenv ~= vim.NIL then
    return shellenv
  else
    return vim.opt.shell:get()
  end
end

---[unknown, neovim-qt, nvui, nvy, neovide]
function getters.gui()
  if exists 'g:nvui' then
    return 'nvui'
  end

  if exists 'g:nvy' then
    return 'nvy'
  end

  if exists 'g:neovide' then
    return 'neovide'
  end

  if exists ':GuiFont' then
    -- TODO: Neovim-qt 自体を検出する方法を見つける
    -- :GuiFont を始め neovim-gui-shim は Linux だと Neovim-qt 以外でもロード
    -- されることがあるよう。Neovim-qt 独自の何かが見つからない間は、とりあえ
    -- ず他の検知を先に置くことで既知の UI は壊さないようにする。
    return 'neovim-qt'
  end

  return 'unknown'
end

function M.path_under_config(path)
  return expand(vim.fn.stdpath 'config' .. '/' .. path)
end

function M.path_under_data(path)
  return expand(vim.fn.stdpath 'data' .. '/' .. path)
end

function M.path_under_github(path)
  return expand('~/dev/github/' .. path)
end

return M
