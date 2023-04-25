local k = require 'rc.lib.keybind'
local env = require 'rc.env'
local vimfn = require 'rc.lib.vimfn'
local cg = get_global_config

-- 追加のファイルタイプ設定
vim.filetype.add {
  extension = {
    xaml = 'xml',
    meta = 'lua',
    ts = 'typescript',
    razor = 'razor',
    cshtml = 'razor',
    jl = 'julia',
    nim = 'nim',
    vala = 'vala',
    cr = 'crystal',
    kt = 'kotlin',
  },
}

vim.g.tex_flavor = 'latex'

require('rc.lib.autocmd').augroup('rc__ftplugin', function(au)
  au('FileType', 'c,cpp', function()
    vim.opt_local.textwidth = 78
  end)

  au('FileType', 'go', function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
  end)

  au('FileType', 'python', function()
    vim.opt_local.textwidth = 78
  end)

  au('FileType', 'rust', function()
    vim.opt_local.textwidth = 100
  end)

  au('FileType', 'lua', function()
    vim.opt_local.textwidth = 78
  end)

  au('FileType', 'vim', function()
    vim.opt_local.shiftwidth = 2
    vim.g.vim_indent_cont = 2
  end)

  au('FileType', 'tex', function()
    --vim.opt_local.textwidth = 0

    -- coc-texlab の forward search の設定を挟んでおく
    -- :CocMachineConfig は Docker ではしんどいので...
    if cg 'editor.ide.framework' == 'coc' then
      if env.is_unix and b(vim.fn.executable 'zathura') then
        vim.fn['coc#config']('texlab.forwardSearch.executable', 'zathura')
        vim.fn['coc#config']('texlab.forwardSearch.args', {
          '-x',
          string.format(
            [[nvim --server '%s' --remote '%%{input}:%%{line}']],
            vim.v.servername
          ),
          '--synctex-forward',
          '%l:0:%f',
          '%p',
        })
      end

      local sumatra_path =
        vimfn.expand [[~\AppData\Local\SumatraPDF\SumatraPDF.exe]]
      if env.is_win32 and b(vim.fn.executable(sumatra_path)) then
        vim.fn['coc#config']('texlab.forwardSearch.executable', sumatra_path)
        vim.fn['coc#config']('texlab.forwardSearch.args', {
          '-forward-search',
          '%f',
          '%l',
          '-inverse-search',
          string.format(
            [[nvim --server "%s" --remote "%%f:%%l"]],
            vim.v.servername
          ),
          '%p',
        })
      end

      k.buf.nno('<Leader>lf', k.cmd 'CocCommand latex.ForwardSearch')
      k.buf.nno('<Leader>ll', k.cmd 'CocCommand latex.Build')
    else
      k.buf.nno('<Leader>lf', 'TexlabForward')
      k.buf.nno('<Leader>ll', 'TexlabBuild')
    end
  end)
end)
