local c = require 'rc.config'

local M = {}

local function padding_lsp_status(status)
  local win = vim.api.nvim_get_current_win()
  local win_width = vim.api.nvim_win_get_width(win)
  local width = math.clamp(60, 5, win_width - 60)
  -- width をオーバーしないところまでとる
  local curr_width = 0
  local cropped = status
    :chars()
    :take_while(function(ch)
      curr_width = curr_width + vim.fn.strdisplaywidth(ch)
      return curr_width < width
    end)
    :to_table()
  cropped = table.concat(cropped)

  local status_width = vim.fn.strdisplaywidth(cropped)
  local whitespace = (' '):rep(width - status_width)
  return cropped .. whitespace
end

local function coc_status()
  local function replace_spinner(s)
    local spinner_map = {
      ['⠋'] = '.',
      ['⠙'] = 'o',
      ['⠹'] = 'O',
      ['⠸'] = '@',
      ['⠼'] = '*',
      ['⠴'] = '.',
      ['⠦'] = 'o',
      ['⠧'] = 'O',
      ['⠇'] = '@',
      ['⠏'] = '*',
    }

    return table.concat(table
      .iter(vim.fn.split(s, [[\zs]]), ipairs)
      :map(function(_, ch)
        return spinner_map[ch] or ch
      end)
      :to_table())
  end

  -- 何もステータスがないときは g:coc_status は定義されていないらしい
  -- (coc#status() を使うと coc がないときにエラーになるから使わない)
  local replaced = replace_spinner(vim.g.coc_status or '')

  -- ステータスを (可能なら) エスケープする
  local ok, lualine_utils = pcall(require, 'lualine.utils.utils')
  if ok then
    replaced = lualine_utils.stl_escape(replaced)
  end

  return replaced
end

local function builtin_status()
  if #vim.lsp.get_active_clients { bufnr = 0 } <= 0 then
    return '(no active LS found)'
  end
  local ok, lsp_status = pcall(require, 'lsp-status')
  if not ok then
    return "('lsp-status' not found)"
  end

  return lsp_status.status()
end

function M.mode()
  local k = require 'rc.lib.keybind'
  local m = vim.fn.mode():sub(1, 1)
  if m == k.t '<C-v>' then
    return '^v'
  end
  return m
end

function M.filetype()
  local ft = vim.opt.filetype:get()
  return ft == '' and '(no type)' or ft
end

function M.lsp_status(padding)
  local function adjuster(s)
    return padding and padding_lsp_status(s) or s
  end

  if c.ide == 'coc' then
    return adjuster(coc_status())
  elseif c.ide == 'builtin' then
    return adjuster(builtin_status())
  end
end

function M.symbol_line()
  if c.ide == 'builtin' then
    -- coc-symbol-line または nvim-navic を利用して symbol line を表示する
    -- nvim-navic がインストール・ロードされていない間もエラーにならないよう
    -- に、また get_location が空の間は > を表示しないようにしたいのでちょっ
    -- と冗長
    local ok, navic = pcall(require, 'nvim-navic')
    if ok then
      local location = navic.get_location()
      if location and location ~= '' then
        return ' > ' .. location
      end
    end
    return ''
  elseif c.ide == 'coc' then
    -- coc-nav で得る
    return table.concat(
      table
        .iter_values(vim.b.coc_nav, ipairs)
        :map(function(v)
          return v.name
        end)
        :to_table(),
      ' > '
    )
  end
end

return M
