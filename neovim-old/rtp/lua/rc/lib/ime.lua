local M = {}

---Check if IME auto-control is already supported by environment or IME-side.
---@return boolean @true if IME auto-control is already supported.
function M.already_supported()
  -- Neovim では基本的に自動サポートはない。
  -- TODO: uim を実行中の UNIX では (Vi 強調モードを通して) サポートされている。
  return false
end

-- 重いので結果をキャッシュする
local detect_cached = false
local detect_cache = nil

---Detect external program type for controlling IME.
---@return string @Type of IME, [windows, fcitx, fcitx5, ime-remote-linux]
function M.detect()
  if detect_cached then
    return detect_cache
  end

  local res = nil
  local env = require 'rc.env'
  if env.is_win32 or env.is_wsl then
    -- Windows or WSL
    if b(vim.fn.executable 'setime.exe') then
      res = 'windows'
    end
  else
    -- UNIX
    if b(vim.fn.executable 'fcitx-remote') then
      res = 'fcitx'
    elseif b(vim.fn.executable 'fcitx5-remote') then
      res = 'fcitx5'
    elseif b(vim.fn.executable 'ime-remote-linux') then
      res = 'ime-remote-linux'
    end
  end

  detect_cache = res
  detect_cached = true

  return res
end

---Get commands for IME controlling.
---@return table @Commands for IME controlling with following properties:
---  - on: Command to enable IME.
---  - off: Command to disable IME.
function M.get_commands()
  local kind = M.detect()
  if kind == 'windows' then
    return {
      on = 'setime.exe on',
      off = 'setime.exe off',
    }
  elseif kind == 'fcitx' then
    return {
      on = 'fcitx-remote -o',
      off = 'fcitx-remote -c',
    }
  elseif kind == 'fcitx5' then
    return {
      on = 'fcitx5-remote -o',
      off = 'fcitx5-remote -c',
    }
  elseif kind == 'ime-remote-linux' then
    return {
      on = 'ime-remote-linux on',
      off = 'ime-remote-linux off',
    }
  else
    require('rc.lib.msg').warn 'IME command not found for this system'
    return {
      on = nil,
      off = nil,
    }
  end
end

--- Function to enable IME.
---Enable or disable IME.
---@param enable boolean @Enable when true, disable otherwise.
---@param do_sleep? boolean @Whether wait before executing command or not.
---@return boolean @true if state was successfully changed.
function M.enable(enable, do_sleep)
  local cmds = M.get_commands()
  local cmd
  if enable then
    cmd = cmds.on
  else
    cmd = cmds.off
  end

  if not cmd then
    -- ignore if IME is not set
    return false
  end

  --if do_sleep then
  --  vim.cmd[[sleep 100m]]
  --end
  vim.fn.system(cmd)
  return vim.v.shell_error == 0
end

return M
