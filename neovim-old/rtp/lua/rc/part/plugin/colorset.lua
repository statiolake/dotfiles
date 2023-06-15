local colorset = require 'rc.lib.colorset'
local cg = get_global_config

local transparent = cg 'ui.transparent'
local use_icons = cg 'ui.useIcons'
local hi = require 'rc.lib.highlight'

local function add(opts)
  local use = require('rc.lib.plugin_manager').use
  local cfg_colorset = cg 'ui.colorset'
  local is_default = table.iter_keys(opts.colorsets, pairs):any(function(key)
    return cfg_colorset == key
  end)

  use {
    opts[1],
    kind = opts.kind,
    name = opts.name,
    path = opts.path,
    url = opts.url,
    simple = is_default,
    before_load = function()
      if opts.before_load then
        opts.before_load()
      end
      for name, colorset_opt in pairs(opts.colorsets) do
        colorset.register(name, colorset_opt)
      end
    end,
  }
end

add {
  name = 'alduin',
  'AlessandroYorba/Alduin',
  -- before_load = function()
  --   -- vim.g.alduin_Shout_Become_Ethereal = 1
  -- end,
  colorsets = {
    alduin = {
      background = 'dark',
      editor = 'alduin',
      lualine = function()
        local alduin_theme = {
          inactive = {
            a = { gui = 'bold', fg = '#1e1e1e', bg = '#946868' },
            b = { bg = '#1e1e1e', fg = '#946868' },
            c = { bg = '#131313', fg = '#f5f5c0' },
          },
          replace = {
            a = { gui = 'bold', fg = '#969696', bg = '#c06800' },
            b = { bg = '#1e1e1e', fg = '#ca720a' },
            c = { bg = '#131313', fg = '#f5f5c0' },
          },
          normal = {
            a = { gui = 'bold', fg = '#1e1e1e', bg = '#946868' },
            b = { bg = '#1e1e1e', fg = '#946868' },
            c = { bg = '#131313', fg = '#f5f5c0' },
          },
          terminal = {
            a = { gui = 'bold', fg = '#1e1e1e', bg = '#94c0c0' },
            b = { bg = '#1e1e1e', fg = '#94c0c0' },
            c = { bg = '#131313', fg = '#f5f5c0' },
          },
          visual = {
            a = { gui = 'bold', fg = '#1e1e1e', bg = '#c06868' },
            b = { bg = '#1e1e1e', fg = '#c06868' },
            c = { bg = '#131313', fg = '#f5f5c0' },
          },
          insert = {
            a = { gui = 'bold', fg = '#1e1e1e', bg = '#fff594' },
            b = { bg = '#1e1e1e', fg = '#fff594' },
            c = { bg = '#131313', fg = '#f5f5c0' },
          },
          command = {
            a = { gui = 'bold', fg = '#1e1e1e', bg = '#94c0c0' },
            b = { bg = '#1e1e1e', fg = '#94c0c0' },
            c = { bg = '#131313', fg = '#f5f5c0' },
          },
        }

        if cg 'ui.transparent' then
          for _mode, color in pairs(alduin_theme) do
            color.c.bg = 'NONE'
          end
        end

        return alduin_theme
      end,
      hook = function()
        if b(vim.g.alduin_Shout_Become_Ethereal) then
          hi.define('Normal', { guibg = '#000000' })
          hi.define('NormalFloat', { guibg = '#1c1c1c' })
          hi.define('CursorLine', { guibg = '#181818' })
          hi.define('SignColumn', { guibg = '#080808' })
          hi.link('Delimiter', 'Operator')
        end

        if transparent then
          hi.define('Normal', { guibg = 'NONE' })
          hi.define('NormalFloat', { guibg = 'NONE' })
          hi.define('SignColumn', { guibg = 'NONE' })
          hi.define('CursorLine', { guibg = 'NONE' })
          hi.define('ColorColumn', { guibg = '#333333' })
          hi.define('String', { guibg = 'NONE' })
          hi.define('Folded', { guibg = 'NONE' })
        end

        hi.define('SubCursor', { guifg = '#000000', guibg = '#6f6f7f' })
        hi.define('VertSplit', { guifg = '#444444', guibg = '#444444' })
        hi.define('WinBar', { guibg = '#181818' })

        hi.define(
          'MatchParen',
          { guibg = 'NONE', gui = 'underline', guisp = 'fg' }
        )
        hi.define('SpecialComment', { gui = 'NONE', guifg = '#afaf7c' })
        hi.link('Conceal', 'NonText')

        hi.define('DenitePrompt', { guifg = '#e08080' })
        hi.link('Substitute', 'IncSearch')

        vim.cmd 'hi! markdownError NONE'

        -- LSP
        hi.define('DefaultErrorLine', {
          guifg = transparent and '#f44747' or 'NONE',
          guibg = transparent and 'NONE' or '#260b0b',
        })
        hi.define('DefaultWarnLine', {
          guifg = transparent and '#eecc77' or 'NONE',
          guibg = transparent and 'NONE' or '#262113',
        })
        hi.define('DefaultInfoLine', { guibg = 'NONE', guifg = 'NONE' })
        hi.define('DefaultHintLine', { guibg = 'NONE', guifg = 'NONE' })
        hi.define('DefaultError', {
          guifg = transparent and '#f44747' or 'NONE',
          guibg = transparent and 'NONE' or '#260b0b',
          gui = 'undercurl',
          guisp = '#f44747',
        })
        hi.define('DefaultWarn', {
          guifg = transparent and '#eecc77' or 'NONE',
          guibg = transparent and 'NONE' or '#262113',
          gui = 'undercurl',
          guisp = '#eecc77',
        })
        hi.define(
          'DefaultInfo',
          { guifg = '#9ad29a', guibg = 'NONE', gui = 'NONE' }
        )
        hi.define('DefaultHint', {
          guifg = 'NONE',
          guibg = 'NONE',
          gui = 'undercurl',
          guisp = '#7a9ad2',
        })
        hi.define(
          'DefaultErrorText',
          { guifg = '#f44747', guibg = 'NONE', gui = 'NONE' }
        )
        hi.define(
          'DefaultWarnText',
          { guifg = '#eecc77', guibg = 'NONE', gui = 'NONE' }
        )
        hi.define(
          'DefaultInfoText',
          { guifg = '#9ad29a', guibg = 'NONE', gui = 'NONE' }
        )
        hi.define(
          'DefaultHintText',
          { guifg = '#7a9ad2', guibg = 'NONE', gui = 'NONE' }
        )
        hi.define(
          'DefaultErrorTextOnErrorLine',
          { guifg = '#f44747', guibg = '#260b0b' }
        )
        hi.define(
          'DefaultWarnTextOnWarnLine',
          { guifg = '#eecc77', guibg = '#262113' }
        )
        hi.define(
          'DefaultInfoTextOnInfoLine',
          { guifg = '#9ad29a', guibg = 'NONE' }
        )
        hi.define(
          'DefaultHintTextOnHintLine',
          { guifg = '#7a9ad2', guibg = 'NONE' }
        )
        hi.define('DefaultReference', { guibg = '#333333' })

        -- Coc
        hi.define('CocUnderline', { guisp = 'fg' })

        -- signify
        hi.define('SignifySignAdd', {
          guifg = '#008787',
          gui = (not use_icons and not transparent) and 'reverse' or nil,
        })
        hi.define('SignifySignChange', {
          guifg = '#005f5f',
          gui = (not use_icons and not transparent) and 'reverse' or nil,
        })
        hi.define('SignifySignDelete', {
          guifg = '#af5f5f',
          gui = (not use_icons and not transparent) and 'reverse' or nil,
        })

        -- gitsigns.nvim
        hi.define('GitSignsAdd', {
          guifg = '#008787',
          gui = (not use_icons and not transparent) and 'reverse' or nil,
        })
        hi.define('GitSignsChange', {
          guifg = '#005f5f',
          gui = (not use_icons and not transparent) and 'reverse' or nil,
        })
        hi.define('GitSignsDelete', {
          guifg = '#af5f5f',
          gui = (not use_icons and not transparent) and 'reverse' or nil,
        })

        -- conflict-marker
        vim.g.conflict_marker_highlight_group = ''
        hi.define('ConflictMarkerBegin', { guibg = '#2f7366' })
        hi.define('ConflictMarkerOurs', { guibg = '#2e5049' })
        hi.define('ConflictMarkerTheirs', { guibg = '#344f69' })
        hi.define('ConflictMarkerEnd', { guibg = '#2f628e' })

        -- vim-illuminate
        hi.link('IlluminatedWordText', 'DefaultReference')

        -- nvim-scrollbar
        hi.define('ScrollbarHandle', { guifg = '#121212', guibg = '#121212' })
        hi.define(
          'ScrollbarSearchHandle',
          { guifg = '#878787', guibg = '#121212' }
        )
        hi.define(
          'ScrollbarErrorHandle',
          { guifg = '#f44747', guibg = '#121212' }
        )
        hi.define(
          'ScrollbarWarnHandle',
          { guifg = '#eecc77', guibg = '#121212' }
        )
        hi.define(
          'ScrollbarInfoHandle',
          { guifg = '#9ad29a', guibg = '#121212' }
        )
        hi.define(
          'ScrollbarHintHandle',
          { guifg = '#7a9ad2', guibg = '#121212' }
        )
        hi.define(
          'ScrollbarMiscHandle',
          { guifg = '#dfdfaf', guibg = '#121212' }
        )
        hi.define('ScrollbarSearch', { guifg = '#878787' })
        hi.define('ScrollbarError', { guifg = '#f44747' })
        hi.define('ScrollbarWarn', { guifg = '#eecc77' })
        hi.define('ScrollbarInfo', { guifg = '#9ad29a' })
        hi.define('ScrollbarHint', { guifg = '#7a9ad2' })
        hi.define('ScrollbarMisc', { guifg = '#dfdfaf' })

        -- vimscript
        hi.link('vimSep', 'Operator')
        hi.link('vimOperParen', 'Operator')
        hi.link('vimParenSep', 'Operator')

        -- typescript
        hi.link('typescriptGlobalObjects', 'Type')
        hi.link('typescriptParens', 'Operator')
        hi.link('typescriptBraces', 'Operator')
        hi.link('typescriptEndColons', 'Operator')
        hi.link('typescriptLogicSymbols', 'Operator')

        -- matlab
        hi.link('matlabSemicolon', 'Operator')
        hi.link('matlabDelimiter', 'Normal')

        -- telescope.nvim
        -- 色を全て無効化しないと、function, field など要素によっては選択中
        -- エントリーの背景色と文字色が同じになってしまい、選択している要素
        -- のラベルが読めなくなってしまう。TelescopeSelection が guifg を尊
        -- 重してくれれば問題ないのだが、そういうわけにはいかないらしい。
        --hi.define('TelescopeMatching', { guifg = 'white', gui = 'bold' })
        --hi.link('TelescopeResultsClass', 'NormalFloat')
        --hi.link('TelescopeResultsComment', 'NormalFloat')
        --hi.link('TelescopeResultsConstant', 'NormalFloat')
        --hi.link('TelescopeResultsDiffAdd', 'NormalFloat')
        --hi.link('TelescopeResultsDiffChange', 'NormalFloat')
        --hi.link('TelescopeResultsDiffDelete', 'NormalFloat')
        --hi.link('TelescopeResultsDiffUntracked', 'NormalFloat')
        --hi.link('TelescopeResultsField', 'NormalFloat')
        --hi.link('TelescopeResultsFunction', 'NormalFloat')
        --hi.link('TelescopeResultsIdentifier', 'NormalFloat')
        --hi.link('TelescopeResultsLineNr', 'NormalFloat')
        --hi.link('TelescopeResultsMethod', 'NormalFloat')
        --hi.link('TelescopeResultsNormal', 'NormalFloat')
        --hi.link('TelescopeResultsNumber', 'NormalFloat')
        --hi.link('TelescopeResultsOperator', 'NormalFloat')
        --hi.link('TelescopeResultsSpecialComment', 'NormalFloat')
        --hi.link('TelescopeResultsStruct', 'NormalFloat')
        --hi.link('TelescopeResultsTitle', 'NormalFloat')
        --hi.link('TelescopeResultsVariable', 'NormalFloat')

        -- nvim-cmp
        hi.define(
          'CmpItemAbbrDeprecated',
          { gui = 'strikethrough', guifg = '#444444' }
        )
        hi.link('CmpItemAbbrMatch', 'Special')
        hi.link('CmpItemAbbrMatchFuzzy', 'Special')
        hi.define('CmpItemKind', { guibg = '#af5f5f', guifg = '#dfdfaf' })
        hi.link('CmpItemKindVariable', 'CmpItemKind')
        hi.link('CmpItemKindInterface', 'CmpItemKind')
        hi.link('CmpItemKindText', 'CmpItemKind')
        hi.link('CmpItemKindFunction', 'CmpItemKind')
        hi.link('CmpItemKindMethod', 'CmpItemKind')
        hi.link('CmpItemKindKeyword', 'CmpItemKind')
        hi.link('CmpItemKindProperty', 'CmpItemKind')
        hi.link('CmpItemKindUnit', 'CmpItemKind')

        -- treesitter
        hi.link('@function.macro', 'Function')
        hi.link('@text.environment', 'Function')
        hi.link('@text.environment.name', 'Special')
        hi.link('@text.math', 'String')
        hi.link('@text.diff.delete.diff', 'DiffDelete')
        hi.link('@text.diff.add.diff', 'DiffAdd')
      end,
    },
  },
}

add {
  'tomasiser/vim-code-dark',
  colorsets = {
    codedark = {
      background = 'dark',
      editor = 'codedark',
      hook = function() end,
    },
  },
}

add {
  'metalelf0/jellybeans-nvim',
  depends = { 'lush.nvim' },
  colorsets = {
    jellybeans = {
      background = 'dark',
      editor = 'jellybeans-nvim',
      hook = function() end,
    },
  },
}

add {
  'morhetz/gruvbox',
  colorsets = {
    gruvbox = {
      background = 'dark',
      editor = 'gruvbox',
      hook = function() end,
    },
  },
}

add {
  'tobi-wan-kenobi/zengarden',
  colorsets = {
    zengarden = {
      background = 'light',
      editor = 'zengarden',
      hook = function() end,
    },
  },
}

add {
  'habamax/vim-colors-defminus',
  colorsets = {
    defminus = {
      background = 'light',
      editor = 'defminus',
      hook = function()
        vim.cmd [[
          hi! MatchParen guibg=NONE ctermbg=NONE
            \ gui=underline cterm=underline guisp=black

          " LSP
          hi! DefaultErrorText guifg=#c82829 guibg=NONE gui=none
          hi! DefaultError guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#c82829
          hi! DefaultWarnText guifg=#ac7b00 guibg=NONE gui=none
          hi! DefaultWarn guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#eecc77
          hi! DefaultHintText guifg=#4271ae guibg=NONE gui=none
          hi! DefaultHint guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#4271ae
          hi! DefaultInfoText guifg=#9ad29a guibg=NONE gui=none
          hi! DefaultInfo guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#9ad29a

          " coc.nvim
          hi! CocHighlightText guibg=NONE

          " conflict-marker
          let g:conflict_marker_highlight_group = ''
          hi ConflictMarkerBegin guibg=#9FE3D6
          hi ConflictMarkerOurs guibg=#D9F4EF
          hi ConflictMarkerTheirs guibg=#D9EDFF
          hi ConflictMarkerEnd guibg=#9FD2FF
          hi link ConflictMarkerSeparator Normal
        ]]
      end,
    },
  },
}

add {
  'cocopon/iceberg.vim',
  colorsets = {

    ['iceberg-light'] = {
      background = 'light',
      editor = 'iceberg',
      hook = function()
        vim.cmd [[
          hi DenitePrompt guifg=#e08080
          hi! link Substitute IncSearch

          " LSP
          hi clear DefaultErrorLine
          hi DefaultErrorText guifg=#f44747 guibg=NONE gui=none
          hi DefaultError guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#f44747
          hi clear DefaultWarnLine
          hi DefaultWarnText guifg=#eecc77 guibg=NONE gui=none
          hi DefaultWarn guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#eecc77
          hi clear DefaultHintLine
          hi DefaultHintText guifg=#7a9ad2 guibg=NONE gui=none
          hi DefaultHint guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#7a9ad2
          hi clear DefaultInfoLine
          hi DefaultInfoText guifg=#9ad29a guibg=NONE gui=none
          hi DefaultInfo guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#9ad29a
          hi DefaultReference guibg=#c9cdd7

          " Rust
          hi! link rustFuncCall Function
        ]]
      end,
    },
    ['iceberg-dark'] = {
      background = 'dark',
      editor = 'iceberg',
      hook = function()
        vim.cmd [[
          hi DenitePrompt guifg=#e08080
          hi! link Substitute IncSearch

          " LSP
          hi clear DefaultErrorLine
          hi DefaultErrorText guifg=#f44747 guibg=NONE gui=none
          hi DefaultError guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#f44747
          hi clear DefaultWarnLine
          hi DefaultWarnText guifg=#eecc77 guibg=NONE gui=none
          hi DefaultWarn guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#eecc77
          hi clear DefaultHintLine
          hi DefaultHintText guifg=#7a9ad2 guibg=NONE gui=none
          hi DefaultHint guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#7a9ad2
          hi clear DefaultInfoLine
          hi DefaultInfoText guifg=#9ad29a guibg=NONE gui=none
          hi DefaultInfo guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#9ad29a
          hi DefaultReference guibg=#333333

          " Rust
          hi! link rustFuncCall Function
        ]]
      end,
    },
  },
}

add {
  'arzg/vim-colors-xcode',
  colorsets = {
    xcode = {
      background = 'light',
      editor = 'xcodelight',
      hook = function()
        vim.cmd [[
          hi! Folded guibg=bg

          " LSP
          hi! DefaultErrorLine guibg=NONE guifg=NONE
          hi! DefaultWarnLine  guibg=NONE guifg=NONE
          hi! DefaultInfoLine  guibg=NONE guifg=NONE
          hi! DefaultHintLine  guibg=NONE guifg=NONE
          hi! DefaultError guibg=NONE guifg=NONE
            \ gui=undercurl cterm=underline guisp=#c82829
          hi! DefaultWarn  guibg=NONE guifg=NONE
            \ gui=undercurl cterm=underline guisp=#4271ae
          hi! DefaultInfo  guibg=NONE guifg=NONE
            \ gui=undercurl cterm=underline guisp=#8959a8
          hi! DefaultHint  guibg=NONE guifg=NONE
            \ gui=undercurl cterm=underline guisp=#3e999f
          hi! DefaultErrorText guifg=#c82829
          hi! DefaultWarnText  guifg=#4271ae
          hi! DefaultInfoText  guifg=#8959a8
          hi! DefaultHintText  guifg=#3e999f

          " conflict-marker
          let g:conflict_marker_highlight_group = ''
          hi ConflictMarkerBegin guibg=#9FE3D6
          hi ConflictMarkerOurs guibg=#D9F4EF
          hi ConflictMarkerTheirs guibg=#D9EDFF
          hi ConflictMarkerEnd guibg=#9FD2FF
          hi link ConflictMarkerSeparator Normal
        ]]
      end,
    },
  },
}

add {
  'NLKNguyen/papercolor-theme',
  colorsets = {
    paper = {
      background = 'light',
      editor = 'PaperColor',
      hook = function()
        vim.cmd [[
          "hi! Normal guibg=#ffffff
          hi! Folded guibg=bg
          hi! LineNr guibg=bg
          hi! NonText guibg=bg guifg=#dfdfdf
          hi! SpecialKey guibg=bg guifg=#dfdfdf
          hi! SignColumn guibg=bg
          hi! Error guibg=bg

          " LSP
          hi! DefaultErrorLine guibg=NONE guifg=NONE
          hi! DefaultWarnLine  guibg=NONE guifg=NONE
          hi! DefaultInfoLine  guibg=NONE guifg=NONE
          hi! DefaultHintLine  guibg=NONE guifg=NONE
          hi! DefaultError guibg=NONE guifg=NONE
            \ gui=undercurl cterm=underline guisp=#c82829
          hi! DefaultWarn  guibg=NONE guifg=NONE
            \ gui=undercurl cterm=underline guisp=#4271ae
          hi! DefaultInfo  guibg=NONE guifg=NONE
            \ gui=undercurl cterm=underline guisp=#8959a8
          hi! DefaultHint  guibg=NONE guifg=NONE
            \ gui=undercurl cterm=underline guisp=#3e999f
          hi! DefaultErrorText guifg=#c82829
          hi! DefaultWarnText  guifg=#4271ae
          hi! DefaultInfoText  guifg=#8959a8
          hi! DefaultHintText  guifg=#3e999f

          " conflict-marker
          let g:conflict_marker_highlight_group = ''
          hi ConflictMarkerBegin guibg=#9FE3D6
          hi ConflictMarkerOurs guibg=#D9F4EF
          hi ConflictMarkerTheirs guibg=#D9EDFF
          hi ConflictMarkerEnd guibg=#9FD2FF
          hi link ConflictMarkerSeparator Normal
        ]]
      end,
    },
  },
}

add {
  'folke/tokyonight.nvim',
  before_load = function()
    vim.g.tokyonight_style = 'night'
  end,
  colorsets = {
    tokyonight = {
      background = 'dark',
      editor = 'tokyonight',
      lualine = 'tokyonight',
      hook = function() end,
    },
  },
}

add {
  'sainnhe/everforest',
  colorsets = {
    everforest = {
      background = 'dark',
      editor = 'everforest',
      lualine = 'everforest',
      hook = function() end,
    },
  },
}

add {
  'rebelot/kanagawa.nvim',
  colorsets = {
    kanagawa = {
      background = 'dark',
      editor = 'kanagawa',
      lualine = 'kanagawa',
      hook = function() end,
    },
  },
}

add {
  'sonph/onehalf',
  subdir = 'vim',
  colorsets = {
    ['onehalf-light'] = {
      background = 'light',
      editor = 'onehalflight',
      hook = function()
        vim.cmd [[
          hi! Normal guibg=#ffffff
        ]]
      end,
    },
    ['onehalf-dark'] = {
      background = 'dark',
      editor = 'onehalfdark',
      hook = function() end,
    },
  },
}

add {
  'mvpopuk/inspired-github.vim',
  colorsets = {
    ['inspired-github'] = {
      background = 'light',
      editor = 'inspired-github',
      hook = function() end,
    },
  },
}

add {
  'projekt0n/github-nvim-theme',
  before_load = function()
    vim.g.github_comment_style = 'NONE'
    vim.g.github_keyword_style = 'NONE'
  end,
  colorsets = {
    ['github-light'] = {
      background = 'light',
      editor = 'github_light',
      hook = function()
        vim.cmd [[
          hi! NonText guifg=#dddddd
          hi! NormalFloat guibg=#eeeeee
          hi! FloatBorder guibg=#eeeeee
          hi! WinBar guibg=#f3f3f3
          hi! VertSplit guibg=#e1e4e8

          hi! DefaultErrorLine guibg=#fffbfc guifg=NONE
          hi! DefaultWarnLine  guibg=#fffbf1 guifg=NONE
          hi! DefaultInfoLine  guibg=NONE guifg=NONE
          hi! DefaultHintLine  guibg=NONE guifg=NONE
          hi! DefaultError guifg=NONE guibg=#fffbfc
            \ gui=undercurl cterm=underline guisp=#cb2431
          hi! DefaultWarn  guifg=NONE guibg=#fffbf1
            \ gui=undercurl cterm=underline guisp=#bf8803
          hi! DefaultInfo  guifg=#9ad29a guibg=NONE gui=NONE
          hi! DefaultHint  guifg=NONE guibg=NONE
            \ gui=undercurl cterm=underline guisp=#7a9ad2
          hi! DefaultErrorText guifg=#cb2431 guibg=NONE gui=NONE
          hi! DefaultWarnText  guifg=#bf8803 guibg=NONE gui=NONE
          hi! DefaultInfoText  guifg=#9ad29a guibg=NONE gui=NONE
          hi! DefaultHintText  guifg=#7a9ad2 guibg=NONE gui=NONE
          hi! DefaultErrorTextOnErrorLine guifg=#cb2431 guibg=#fffbfc
          hi! DefaultWarnTextOnWarnLine   guifg=#bf8803 guibg=#fffbf1
          hi! DefaultInfoTextOnInfoLine   guifg=#9ad29a guibg=NONE
          hi! DefaultHintTextOnHintLine   guifg=#7a9ad2 guibg=NONE
          hi! DefaultReference guibg=#c6eed2
        ]]
      end,
    },
  },
}

add {
  'Mofiqul/vscode.nvim',
  colorsets = {
    ['vscode-dark'] = {
      background = 'dark',
      editor = 'vscode',
      hook = function() end,
    },
    ['vscode-light'] = {
      background = 'light',
      editor = 'vscode',
      hook = function() end,
    },
  },
}
