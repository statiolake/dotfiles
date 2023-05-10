local manager = require 'rc.lib.plugin_manager'
local use, use_as_deps = manager.use, manager.use_as_deps
local cmd = require 'rc.lib.command'
local msg = require 'rc.lib.msg'
local k = require 'rc.lib.keybind'
local ac = require 'rc.lib.autocmd'
local env = require 'rc.env'
local vimfn = require 'rc.lib.vimfn'
local colorset = require 'rc.lib.colorset'
local hi = require 'rc.lib.highlight'
local cg = get_global_config

-- Interface {{{
-- 外の Neovim-qt を利用するときは使うべし
use {
  'equalsraf/neovim-gui-shim',
  enabled = vim.fn.getenv 'DOCKERMAN_ATTACHED' == '1',
}

use {
  'nvim-lualine/lualine.nvim',
  depends = {
    'lush.nvim',
  },
  opt_depends = {
    'nvim-gps',
    'nvim-navic',
  },
  simple = true,
  after_load = function()
    local stl = require 'rc.statusline'

    local use_icons = cg 'ui.useIcons'

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

    ac.on_vimenter(function()
      require('lualine').setup {
        options = {
          icons_enabled = use_icons,
          theme = alduin_theme,
          component_separators = '│',
          section_separators = use_icons and { left = '', right = '' }
            or '',
          disabled_filetypes = {},
          always_divide_middle = true,
          globalstatus = b(vim.fn.has 'nvim-0.7'),
          refresh = {
            statusline = 125,
          },
        },
        sections = {
          lualine_a = { stl.mode },
          lualine_b = {
            'branch',
            {
              'diff',
              symbols = {
                added = '+',
                modified = use_icons and '' or '~',
                removed = '-',
              },
            },
            'diagnostics',
          },
          lualine_c = pack {
            {
              'filename',
              symbols = {
                modified = use_icons and ' ' or '[+]',
                readonly = use_icons and ' ' or '[-]', -- Text to show when the file is non-modifiable or readonly.
                unnamed = '(untitled)',
              },
            },
            stl.symbol_line,
          },
          lualine_x = pack {
            when(not cg 'editor.simpleMode', function()
              return stl.lsp_status(false)
            end),
            when(cg 'editor.simpleMode', stl.simple_mode_status),
          },
          lualine_y = {
            'encoding',
            {
              'fileformat',
              symbols = {
                unix = 'unix',
                dos = 'dos',
                mac = 'mac',
              },
            },
            'filetype',
          },
          lualine_z = { 'location', 'progress' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        extensions = {},
      }
    end)
  end,
}

use {
  'kyazdani42/nvim-tree.lua',
  depends = pack {
    when(cg 'ui.useIcons', 'nvim-web-devicons'),
  },
  -- これ cmd にしたいけど、すると初回にファイルを見つけてくれなくなるバグ？
  -- があるのでしない。
  --cmd = 'NvimTreeToggle',
  after_load = function()
    local function on_attach(bufnr)
      local api = require 'nvim-tree.api'

      local function opts(desc)
        return {
          desc = 'nvim-tree: ' .. desc,
          buffer = bufnr,
          noremap = true,
          silent = true,
          nowait = true,
        }
      end

      k.n('<C-]>', api.tree.change_root_to_node, opts 'CD')
      --k.n('<C-e>', api.node.open.replace_tree_buffer, opts 'Open: In Place')
      k.n('<C-k>', api.node.show_info_popup, opts 'Info')
      k.n('<C-r>', api.fs.rename_sub, opts 'Rename: Omit Filename')
      k.n('<C-t>', api.node.open.tab, opts 'Open: New Tab')
      k.n('<C-v>', api.node.open.vertical, opts 'Open: Vertical Split')
      k.n('<C-x>', api.node.open.horizontal, opts 'Open: Horizontal Split')
      k.n('<BS>', api.node.navigate.parent_close, opts 'Close Directory')
      k.n('<CR>', api.node.open.edit, opts 'Open')
      k.n('<Tab>', api.node.open.preview, opts 'Open Preview')
      k.n('>', api.node.navigate.sibling.next, opts 'Next Sibling')
      k.n('<', api.node.navigate.sibling.prev, opts 'Previous Sibling')
      k.n('.', api.node.run.cmd, opts 'Run Command')
      k.n('-', api.tree.change_root_to_parent, opts 'Up')
      k.n('a', api.fs.create, opts 'Create')
      k.n('bmv', api.marks.bulk.move, opts 'Move Bookmarked')
      k.n('B', api.tree.toggle_no_buffer_filter, opts 'Toggle No Buffer')
      k.n('c', api.fs.copy.node, opts 'Copy')
      k.n('C', api.tree.toggle_git_clean_filter, opts 'Toggle Git Clean')
      k.n('[c', api.node.navigate.git.prev, opts 'Prev Git')
      k.n(']c', api.node.navigate.git.next, opts 'Next Git')
      k.n('d', api.fs.remove, opts 'Delete')
      k.n('D', api.fs.trash, opts 'Trash')
      k.n('E', api.tree.expand_all, opts 'Expand All')
      k.n('e', api.fs.rename_basename, opts 'Rename: Basename')
      k.n(']e', api.node.navigate.diagnostics.next, opts 'Next Diagnostic')
      k.n('[e', api.node.navigate.diagnostics.prev, opts 'Prev Diagnostic')
      k.n('F', api.live_filter.clear, opts 'Clean Filter')
      k.n('f', api.live_filter.start, opts 'Filter')
      k.n('g?', api.tree.toggle_help, opts 'Help')
      k.n('gy', api.fs.copy.absolute_path, opts 'Copy Absolute Path')
      k.n('H', api.tree.toggle_hidden_filter, opts 'Toggle Dotfiles')
      k.n('I', api.tree.toggle_gitignore_filter, opts 'Toggle Git Ignore')
      k.n('J', api.node.navigate.sibling.last, opts 'Last Sibling')
      k.n('K', api.node.navigate.sibling.first, opts 'First Sibling')
      k.n('m', api.marks.toggle, opts 'Toggle Bookmark')
      k.n('o', api.node.open.edit, opts 'Open')
      k.n('O', api.node.open.no_window_picker, opts 'Open: No Window Picker')
      k.n('p', api.fs.paste, opts 'Paste')
      k.n('P', api.node.navigate.parent, opts 'Parent Directory')
      k.n('q', api.tree.close, opts 'Close')
      k.n('r', api.fs.rename, opts 'Rename')
      k.n('R', api.tree.reload, opts 'Refresh')
      k.n('s', api.node.run.system, opts 'Run System')
      k.n('S', api.tree.search_node, opts 'Search')
      k.n('U', api.tree.toggle_custom_filter, opts 'Toggle Hidden')
      k.n('W', api.tree.collapse_all, opts 'Collapse')
      k.n('x', api.fs.cut, opts 'Cut')
      k.n('y', api.fs.copy.filename, opts 'Copy Name')
      k.n('Y', api.fs.copy.relative_path, opts 'Copy Relative Path')
      k.n('<2-LeftMouse>', api.node.open.edit, opts 'Open')
      k.n('<2-RightMouse>', api.tree.change_root_to_node, opts 'CD')

      k.n('<CR>', api.node.open.edit, opts 'Open')
      k.n('<C-Return>', api.tree.change_root_to_node, opts 'CD')
      k.n('<C-v>', api.node.open.vertical, opts 'Open: Vertical Split')
      k.n('<C-x>', api.node.open.horizontal, opts 'Open: Horizontal Split')
      k.n('<C-t>', api.node.open.tab, opts 'Open: New Tab')
      k.n('R', api.tree.reload, opts 'Refresh')
      k.n('a', api.fs.create, opts 'Create')
      k.n('m', api.fs.rename_sub, opts 'Rename: Omit Filename')
      k.n('x', api.fs.cut, opts 'Cut')
      k.n('y', api.fs.copy.node, opts 'Copy')
      k.n('p', api.fs.paste, opts 'Paste')
      k.n('Y', api.fs.copy.relative_path, opts 'Copy Relative Path')
      k.n('gy', api.fs.copy.absolute_path, opts 'Copy Absolute Path')
      k.n('<A-Return>', api.node.run.system, opts 'Run System')
      k.n('g?', api.tree.toggle_help, opts 'Help')
      k.n('I', api.tree.toggle_gitignore_filter, opts 'Toggle Git Ignore')
      k.n('H', api.tree.toggle_hidden_filter, opts 'Toggle Dotfiles')
      k.n('-', api.tree.change_root_to_parent, opts 'Up')
      k.n('<BS>', api.node.navigate.parent, opts 'Parent Directory')
    end

    ac.on_vimenter(function()
      local use_icons = cg 'ui.useIcons'
      cmd.add('NvimTreeChangeToCwd', function()
        require('nvim-tree.lib').change_dir(vimfn.expand('%:h', nil, nil))
      end)
      k.n('<C-b>', k.cmd 'NvimTreeToggle')
      require('nvim-tree').setup {
        on_attach = on_attach,
        disable_netrw = true,
        hijack_netrw = true,
        reload_on_bufenter = true,
        update_cwd = true,
        diagnostics = {
          enable = true,
          icons = cg('ui.signs').diagnostics,
        },
        update_focused_file = {
          enable = true,
          update_cwd = false,
          ignore_list = {},
        },
        git = {
          ignore = false,
        },
        filesystem_watchers = {
          enable = true,
        },
        actions = {
          change_dir = { global = false },
          open_file = { quit_on_open = false },
        },
        renderer = {
          indent_markers = {
            enable = true,
          },
          icons = {
            git_placement = 'after',
            show = {
              git = true,
              folder = true,
              file = use_icons,
              folder_arrow = use_icons,
            },
            glyphs = {
              git = {
                unstaged = use_icons and '' or '~',
                staged = use_icons and '' or '@',
                unmerged = use_icons and '' or '!',
                renamed = use_icons and '' or '>',
                untracked = use_icons and '' or '+',
                deleted = use_icons and '' or '-',
                ignored = use_icons and '◌' or '_',
              },
              folder = {
                default = use_icons and '' or '+',
                open = use_icons and '' or '~',
                empty = use_icons and '' or '+',
                empty_open = use_icons and '' or '+',
                symlink = use_icons and '' or 'L',
                symlink_open = use_icons and '' or 'L',
              },
            },
          },
        },
      }
    end)
  end,
}

use {
  'liuchengxu/vista.vim',
  enabled = cg 'editor.ide.framework' ~= 'coc',
  before_load = function()
    vim.g['vista#renderer#enable_icon'] = cg 'ui.useIcons'
    local ide = cg 'editor.ide.framework'
    vim.g['vista_default_executive'] = ide == 'coc' and 'coc' or 'nvim_lsp'
    k.nno('<C-t>', k.cmd 'Vista!!')
  end,
}

use {
  'sindrets/diffview.nvim',
  depends = { 'plenary.nvim' },
  after_load = function()
    local use_icons = cg 'ui.useIcons'
    require('diffview').setup {
      icons = { -- Only applies when use_icons is true.
        folder_closed = '',
        folder_open = '',
      },
      signs = {
        fold_open = use_icons and '' or '~',
        fold_closed = use_icons and '' or '+',
      },
      use_icons = use_icons,
    }
  end,
}

use_as_deps {
  'nvim-telescope/telescope.nvim',
  depends = {
    'popup.nvim',
    'plenary.nvim',
    'telescope-ui-select.nvim',
  },
  after_load = function()
    k.nno('<C-e>', k.cmd 'Telescope find_files')
    k.nno('<C-f>', k.cmd 'Telescope live_grep')
    k.nno('<C-q>', k.cmd 'Telescope buffers')
    k.nno('<C-s>', k.cmd 'Telescope resume')

    -- リザルト画面が fold されてしまう問題を修正
    -- https://github.com/nvim-telescope/telescope.nvim/issues/991
    ac.augroup('rc__telescope_fix_fold', function(au)
      au('FileType', 'TelescopeResults', function()
        vim.opt_local.foldenable = false
      end)
    end)

    local border = cg 'ui.border'
    local function extract(c)
      -- border は { char, highlight } のリストということもある
      return c[1] or c
    end

    local borderchars = {
      extract(border[2]),
      extract(border[4]),
      extract(border[6]),
      extract(border[8]),
      extract(border[1]),
      extract(border[3]),
      extract(border[5]),
      extract(border[7]),
    }

    local telescope = require 'telescope'

    telescope.setup {
      defaults = {
        mappings = {
          i = {
            -- skkeleton の有効化と重複するので無効化しておく
            ['<C-j>'] = false,
          },
        },
        borderchars = borderchars,
      },
    }

    telescope.load_extension 'ui-select'

    -- デフォルトのハイライト色を設定する
    colorset.register_editor_colorscheme_hook(function()
      vim.cmd [[
        hi! link TelescopeBorder FloatBorder
        hi! link TelescopeNormal NormalFloat
      ]]
    end)
  end,
}

use_as_deps {
  'nvim-telescope/telescope-ui-select.nvim',
}

use {
  'alvarosevilla95/luatab.nvim',
  depends = pack {
    when(cg 'ui.useIcons', 'nvim-web-devicons'),
  },
  after_load = function()
    local opts = {}

    if not cg 'ui.useIcons' then
      opts.devicon = function()
        return ''
      end
    end

    require('luatab').setup(opts)
  end,
}

-- use {
--   'petertriho/nvim-scrollbar',
--   after_load = function()
--     require('scrollbar').setup {
--       set_highlights = false,
--     }
--   end,
-- }

-- use {
--   'kevinhwang91/nvim-hlslens',
--   depends = {
--     'vim-asterisk',
--     'nvim-scrollbar',
--   },
--   after_load = function()
--     local hlslens = require 'hlslens'
--     k.nno('n', function()
--       vim.cmd(string.format('normal! %dn', vim.v.count1))
--       hlslens.start()
--     end)
--     k.nno('N', function()
--       vim.cmd(string.format('normal! %dN', vim.v.count1))
--       hlslens.start()
--     end)
--     k.n('*', [[<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>]])
--     k.n('#', [[<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>]])
--     k.n(
--       'g*',
--       [[<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>]]
--     )
--     k.n(
--       'g#',
--       [[<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>]]
--     )
--     k.x('*', [[<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>]])
--     k.x('#', [[<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>]])
--     k.x(
--       'g*',
--       [[<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>]]
--     )
--     k.x(
--       'g#',
--       [[<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>]]
--     )
--     require('scrollbar.handlers.search').setup()
--   end,
-- }

use 'hotwatermorning/auto-git-diff'

use {
  'simnalamburt/vim-mundo',
  before_load = function()
    k.nno('<A-z>', k.cmd 'MundoToggle')
  end,
}

use {
  'nvim-pack/nvim-spectre',
  depends = { 'plenary.nvim' },
  enabled = cg 'editor.ide.framework' ~= 'coc',
  after_load = function()
    ac.on_vimenter(function()
      local spectre = require 'spectre'
      cmd.add('Spectre', spectre.open)
      k.nno('<A-f>', spectre.open)
      spectre.setup()
    end)
  end,
}

use {
  't9md/vim-quickhl',
  simple = true,
  before_load = function()
    k.n('+', '<Plug>(quickhl-manual-this-whole-word)')
    k.x('+', '<Plug>(quickhl-manual-this)')
    k.n('-', '<Plug>(quickhl-manual-clear)')
    k.x('-', '<Plug>(quickhl-manual-clear)')
    k.n('<Leader>M', '<Plug>(quickhl-manual-reset)')
    k.x('<Leader>M', '<Plug>(quickhl-manual-reset)')

    cmd.add('NoQuickHl', vim.fn['quickhl#manual#reset'])
  end,
}

-- floating buffer がいろいろと悪さをするので
-- use {
--   'wellle/context.vim',
--   opt_depends = { 'nvim-tree.lua', 'vim-floaterm' },
--   after_load = function()
--     -- gH でトグル
--     k.nno('gH', k.cmd 'ContextToggle')
--
--     -- floaterm, nvim-tree の開閉のたびに有効/無効化する。相性が悪いみたいなの
--     -- で
--     local automatically_hided = false
--     local function on_disable_event()
--       if vim.fn['context#util#active']() ~= 0 then
--         automatically_hided = true
--         vim.cmd [[ContextDisable]]
--       end
--     end
--     local function on_enable_event()
--       if vim.fn['context#util#active']() == 0 and automatically_hided then
--         automatically_hided = false
--         vim.cmd [[ContextEnable]]
--       end
--     end
--
--     -- floaterm
--     ac.augroup('rc__context_floaterm', function(au)
--       au('User', 'FloatermOpen', on_disable_event)
--       au('User', 'CustomFloatermOpen', on_disable_event)
--       au('User', 'CustomFloatermClose', on_enable_event)
--     end)
--
--     -- nvim-tree
--     local ok, event = pcall(require, 'nvim-tree.events')
--     if not ok then
--       return
--     end
--     event.on_tree_open(on_disable_event)
--     event.on_tree_close(on_enable_event)
--   end,
-- }

use {
  'voldikss/vim-floaterm',
  before_load = function()
    local border = cg 'ui.border'
    local function extract(c)
      -- border は { char, highlight } のリストということもある
      return c[1] or c
    end

    vim.g.floaterm_borderchars = {
      extract(border[2]),
      extract(border[4]),
      extract(border[6]),
      extract(border[8]),
      extract(border[1]),
      extract(border[3]),
      extract(border[5]),
      extract(border[7]),
    }

    colorset.register_editor_colorscheme_hook(function()
      hi.link('FloatermBorder', 'FloatBorder')
    end)

    local keys = { '<C-@>', '<C-\\>' }
    for _, key in ipairs(keys) do
      k.add({ 'n', 't' }, key, function()
        local floaterm_name = 'main_shell_terminal'
        if vim.fn['floaterm#terminal#get_bufnr'](floaterm_name) ~= -1 then
          vim.cmd.FloatermToggle { floaterm_name }
          local opened = vim.fn['floaterm#window#find']() ~= 0
          ac.emit(
            'User',
            opened and 'CustomFloatermOpen' or 'CustomFloatermClose'
          )
        else
          vim.cmd.FloatermNew {
            '--height=0.8',
            '--width=0.8',
            '--wintype=float',
            '--position=center',
            '--autoclose=2',
            string.format('--name=%s', floaterm_name),
            env.shell,
          }
        end
      end)
    end
  end,
}

if env.is_unix then
  -- unix でなければインストールごとやめたいので enabled ではなくここで止める
  use_as_deps {
    'junegunn/fzf',
    -- .zshrc などを書き換えられたくない
    build = '!./install --no-update-config',
  }

  use_as_deps {
    'junegunn/fzf.vim',
    depends = { 'fzf' },
    before_load = function()
      vim.g.fzf_command_prefix = 'Fzf'

      local function build_quickfix_list(lines)
        vim.fn['setqflist'](table
          .iter_values(lines, ipairs)
          :map(function(line)
            return { filename = line }
          end)
          :to_table())
      end

      vim.g.fzf_action = {
        ['alt-q'] = build_quickfix_list,
        ['ctrl-t'] = 'tab split',
        ['ctrl-x'] = 'split',
        ['ctrl-v'] = 'vsplit',
      }

      k.n('<C-e>', k.cmd 'FzfFiles')
      k.n('<C-f>', k.cmd 'FzfRg')
      k.n('<C-q>', k.cmd 'FzfBuffers')
    end,
  }

  use_as_deps {
    'gfanto/fzf-lsp.nvim',
    depends = { 'fzf.vim' },
    after_load = function()
      require('fzf_lsp').setup()
    end,
  }
end

use {
  'stevearc/dressing.nvim',
  after_load = function()
    require('dressing').setup {
      select = {
        backend = { 'fzf', 'telescope' },
      },
    }
  end,
}
-- }}}

-- Edit {{{

use {
  'windwp/nvim-autopairs',
  enabled = cg 'editor.ide.framework' ~= 'coc',
  simple = true,
  after_load = function()
    require('nvim-autopairs').setup {
      fast_wrap = { map = '<M-w>' },
      disable_filetype = { 'TelescopePrompt', 'vim' },
      map_cr = false,
    }
  end,
}

use {
  'tpope/vim-endwise',
  enabled = cg 'editor.ide.framework' ~= 'coc',
}

use {
  'alvan/vim-closetag',
  enabled = cg 'editor.ide.framework' ~= 'coc',
  before_load = function()
    -- filenames like *.xml, *.html, *.xhtml, ...
    -- These are the file extensions where this plugin is enabled.
    vim.g.closetag_filenames =
      '*.html,*.xhtml,*.phtml,*.xaml,*.xml,*.jsx,*.tsx'

    -- filenames like *.xml, *.xhtml, ...
    -- This will make the list of non-closing tags self-closing in the
    -- specified files.
    vim.g.closetag_xhtml_filenames = '*.xhtml,*.xml,*.xaml,*.jsx'

    -- filetypes like xml, html, xhtml, ...
    -- These are the file types where this plugin is enabled.
    vim.g.closetag_filetypes =
      'html,xhtml,phtml,xml,javascriptreact,typescriptreact'

    -- filetypes like xml, xhtml, ...
    -- This will make the list of non-closing tags self-closing in the
    -- specified files.
    vim.g.closetag_xhtml_filetypes =
      'xhtml,xml,javascriptreact,typescriptreact'

    -- integer value [0|1]
    -- This will make the list of non-closing tags case-sensitive
    -- (e.g. `<Link>` will be closed while `<link>` won't.)
    vim.g.closetag_emptyTags_caseSensitive = 1

    -- dict
    -- Disables auto-close if not in a "valid" region (based on filetype)
    vim.g.closetag_regions = {
      ['typescript.tsx'] = 'jsxRegion,tsxRegion',
      ['javascript.jsx'] = 'jsxRegion',
      ['typescriptreact'] = 'jsxRegion,tsxRegion',
      ['javascriptreact'] = 'jsxRegion',
    }

    -- Shortcut for closing tags, default is '>'
    vim.g.closetag_shortcut = '>'

    -- Add > at current position without closing the current tag, default is ''
    vim.g.closetag_close_shortcut = '<leader>>'
  end,
}

use {
  'andymass/vim-matchup',
  simple = true,
  before_load = function()
    vim.g.matchup_matchpref = {
      html = {
        tagnameonly = 1,
      },
      xml = {
        tagnameonly = 1,
      },
    }
    vim.g.matchup_matchparen_enabled = 1
  end,
}

use {
  'haya14busa/vim-asterisk',
  simple = true,
  before_load = function()
    k.nx('*', '<Plug>(asterisk-z*)')
    k.nx('#', '<Plug>(asterisk-z#)')
    k.nx('g*', '<Plug>(asterisk-gz*)')
    k.nx('g#', '<Plug>(asterisk-gz#)')
    vim.g['asterisk#keeppos'] = 1
  end,
}

use {
  'phaazon/hop.nvim',
  simple = true,
  after_load = function()
    local hop = require 'hop'
    hop.setup {}
    k.nvo('<Leader>w', hop.hint_words)
    k.nvo('<Leader>j', hop.hint_lines)
    k.nvo('<Leader>k', hop.hint_lines)
  end,
}

use {
  'numToStr/Comment.nvim',
  simple = true,
  after_load = function()
    require('Comment').setup {}
  end,
}

use {
  'kana/vim-textobj-entire',
  simple = true,
  depends = { 'vim-textobj-user' },
}

use {
  'kana/vim-textobj-indent',
  simple = true,
  depends = { 'vim-textobj-user' },
}

use_as_deps 'kana/vim-textobj-user'

use {
  'tpope/vim-surround',
  simple = true,
}

use {
  'statiolake/vim-evalvis',
  simple = true,
  before_load = function()
    vim.g['evalvis#language'] = 'python3'
    k.x('<C-e>', '<Plug>(evalvis-eval)')
  end,
}

-- use {
--   'mg979/vim-visual-multi',
--   before_load = function()
--     vim.g.VM_leader = '\\'
--     vim.g.VM_Mono_hl = 'SubCursor'
--     vim.g.VM_maps = {
--       ['Find Under'] = '<C-l>',
--       ['Find Subword Under'] = '<C-l>',
--       ['Select All'] = '<C-A-l>',
--       ['Add Cursor Down'] = '<M-j>',
--       ['Add Cursor Up'] = '<M-k>',
--       ['Undo'] = 'u',
--       ['Redo'] = '<C-r>',
--       ['I CtrlF'] = '<A-l>',
--       ['I CtrlB'] = '<A-h>',
--     }

--     local bsmap = nil
--     ac.augroup('rc__multi_autopairs_integ', function(au)
--       au('User', 'visual_multi_start', function()
--         bsmap = vim.fn.maparg('<BS>', 'i', false, true)
--         if bsmap then
--           k.iun(
--             '<BS>',
--             { noremap = b(bsmap.noremap), buffer = b(bsmap.buffer) }
--           )
--         end
--       end)
--       au('User', 'visual_multi_exit', function()
--         if bsmap then
--           k.i('<BS>', bsmap.rhs, {
--             noremap = b(bsmap.noremap),
--             buffer = b(bsmap.buffer),
--             expr = b(bsmap.expr),
--           })
--         end
--       end)
--     end)
--   end,
-- }

use {
  'tpope/vim-repeat',
  simple = true,
}

use {
  -- :s 拡張 (:S) 他
  'tpope/vim-abolish',
  simple = true,
  before_load = function()
    local function feed(keys)
      return function()
        vim.api.nvim_feedkeys(k.t(keys), '', false)
      end
    end

    cmd.add('ToSnakeCase', feed 'crs')
    cmd.add('ToUpperCase', feed 'cru')
    cmd.add('ToDashCase', feed 'cr-')
    cmd.add('ToDotCase', feed 'cr.')
    cmd.add('ToPascalCase', feed 'crm')
    cmd.add('ToCamelCase', feed 'crc')
  end,
}

-- use {
--   'monaqa/dial.nvim',
--   simple = true,
--   before_load = function()
--     k.nno('<C-a>', '<Plug>(dial-increment)')
--     k.nno('<C-x>', '<Plug>(dial-decrement)')
--     k.vno('<C-a>', '<Plug>(dial-increment)')
--     k.vno('<C-x>', '<Plug>(dial-decrement)')
--     k.vno('g<C-a>', 'g<Plug>(dial-increment)')
--     k.vno('g<C-x>', 'g<Plug>(dial-decrement)')
--   end,
-- }

use {
  'dhruvasagar/vim-table-mode',
  before_load = function()
    vim.g.table_mode_corner = '|'
  end,
}

use {
  'sentriz/vim-print-debug',
  before_load = function()
    vim.g.print_debug_templates = {
      go = [[fmt.Printf("+++ {}\n")]],
      python = [[print(f"+++ {}")]],
      javascript = [[console.log(`+++ {}`);]],
      c = [[printf("+++ {}\n");]],
      cpp = [[std::cout << "+++ {}" << std::endl;]],
      rust = [[println!("+++ {}");]],
      cs = [[Debug.WriteLine("+++ {}");]],
    }
    k.nno('<Leader>p', function()
      vim.fn['print_debug#print_debug']()
    end)
  end,
}

use 'thinca/vim-partedit'

-- }}}

-- Readability {{{

-- use 'lukas-reineke/indent-blankline.nvim'

-- use {
--   'nathanaelkane/vim-indent-guides',
--   after_load = function()
--     vim.g.indent_guides_enable_on_vim_startup = true
--   end,
-- }

use {
  'bronson/vim-trailing-whitespace',
  simple = true,
  before_load = function()
    vim.g.extra_whitespace_ignored_filetypes = {
      'defx',
      'lsp-installer',
      'TelescopePrompt',
      'markdown',
      'terminal',
    }
  end,
}

use {
  'lewis6991/gitsigns.nvim',
  depends = { 'plenary.nvim' },
  enabled = cg 'editor.ide.framework' ~= 'coc',
  after_load = function()
    local use_icons = cg 'ui.useIcons'
    require('gitsigns').setup {
      signs = {
        add = {
          hl = 'GitSignsAdd',
          text = use_icons and '┃' or '+',
          numhl = 'GitSignsAddNr',
          linehl = 'GitSignsAddLn',
        },
        change = {
          hl = 'GitSignsChange',
          text = use_icons and '┃' or '~',
          numhl = 'GitSignsChangeNr',
          linehl = 'GitSignsChangeLn',
        },
        delete = {
          hl = 'GitSignsDelete',
          text = use_icons and '' or '_',
          numhl = 'GitSignsDeleteNr',
          linehl = 'GitSignsDeleteLn',
        },
        topdelete = {
          hl = 'GitSignsDelete',
          text = use_icons and '' or '‾',
          numhl = 'GitSignsDeleteNr',
          linehl = 'GitSignsDeleteLn',
        },
        changedelete = {
          hl = 'GitSignsChange',
          text = use_icons and '┃' or '~',
          numhl = 'GitSignsChangeNr',
          linehl = 'GitSignsChangeLn',
        },
      },
      current_line_blame = true,
      on_attach = function(bufnr)
        local _ = bufnr

        k.n(
          ']c',
          "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'",
          { expr = true }
        )
        k.n(
          '[c',
          "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'",
          { expr = true }
        )

        -- テキストオブジェクト
        k.add({ 'o', 'x' }, 'ih', k.cmd 'Gitsigns select_hunk')
      end,
      diff_opts = {
        internal = true,
      },
    }
  end,
}

--use {
--  'mhinz/vim-signify',
--  enabled = cg'editor.ide.framework' ~= 'coc',
--  before_load = function()
--    vim.g.signify_sign_add = '+'
--    vim.g.signify_sign_delete = '_'
--    vim.g.signify_sign_delete_first_line = '‾'
--    vim.g.signify_sign_change = '~'
--  end,
--}

use {
  'rhysd/conflict-marker.vim',
  simple = true,
  enabled = cg 'editor.ide.framework' ~= 'coc',
  before_load = function()
    vim.g.conflict_marker_begin = '^<<<<<<< .*$'
    vim.g.conflict_marker_end = '^>>>>>>> .*$'
  end,
}

use 'mechatroner/rainbow_csv'

use {
  'norcalli/nvim-colorizer.lua',
  enabled = cg 'editor.ide.framework' ~= 'coc',
  after_load = function()
    -- termguicolors が設定されていないといけないらしいので遅延する
    ac.on_vimenter(function()
      require('colorizer').setup({ '*' }, {
        RGB = true, -- #RGB
        RRGGBB = true, -- #RRGGBB
        names = true, -- Blue などの色名
        RRGGBBAA = true, -- #RRGGBBAA
        rgb_fn = true, -- CSS の rgb(), rgba()
        hsl_fn = true, -- CSS の hsl(), hsla()
        css = true, -- CSS の機能: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = true, -- CSS の関数: rgb_fn, hsl_fn
        mode = 'background', -- [foreground, background]
      })
    end)
  end,
}

use {
  'statiolake/vim-fontzoom',
  simple = true,
  before_load = function()
    vim.g.fontzoom_no_default_key_mappings = 1
    k.n('g^', '<Plug>(fontzoom-larger)')
    k.n('g-', '<Plug>(fontzoom-smaller)')
  end,
}

-- }}}

-- Other {{{

use {
  'tpope/vim-sleuth',
  simple = true,
}

use 'dstein64/vim-startuptime'

-- gf 拡張

use {
  'wsdjeg/vim-fetch',
  simple = true,
  before_load = function()
    k.nx('gf', 'gF')
  end,
}

use {
  'tyru/open-browser.vim',
  before_load = function()
    k.nx('gx', '<Plug>(openbrowser-open)')
    k.nx('g?', '<Plug>(openbrowser-search)')
  end,
}

use {
  'thinca/vim-quickrun',
  depends = { 'vim-quickrun-runner-nvimterm' },
  before_load = function()
    local deepcopy = require('rc.lib.lang.object').deepcopy

    -- full_pred[&filetype](lines) が true なら、この lines は
    -- part_{filetype} ではなく {filetype} で実行される。
    -- これはあとで setup_{filetype} のところで個別に設定する
    local full_pred = {}

    local function setup_proass(config)
      config.proass = {
        exec = { 'procon-assistant run --force-compile' },
        ['hook/shebang/enable'] = 0,
        ['outputter/error/error'] = 'buffer',
      }
    end

    local function setup_cpp(config)
      config['cpp'] = {
        command = 'clang++',
        tempfile = '%{tempname()}.cpp',
      }

      local cmdopt = {
        '-Wall',
        '-Wextra',
        '-std=c++20',
      }
      if env.is_win32 then
        -- Windows の clang は MSVC のヘッダを使うが、そこで使われている諸々
        -- を許可する
        cmdopt = {
          unpack(cmdopt),
          '-Xclang',
          '-flto-visibility-public-std',
          '-fno-delayed-template-parsing',
        }
      end

      config.cpp['cmdopt'] = table.concat(cmdopt, ' ')

      if env.is_win32 then
        config.cpp['exec'] = {
          '%c %o %s -o %s:p:r.exe',
          '%s:p:r.exe %a',
        }
        config.cpp['hook/sweep/files'] = { '%S:p:r.exe' }
      else
        config.cpp['exec'] = {
          '%c %o %s -o %s:p:r',
          '%s:p:r %a',
        }
        config.cpp['hook/sweep/files'] = { '%S:p:r' }
      end

      -- part_cpp
      config.part_cpp = deepcopy(config.cpp)
      config.part_cpp['hook/shebang/enable'] = 0
      config.part_cpp['hook/eval/enable'] = 1
      config.part_cpp['hook/eval/template'] = table.concat({
        '#include <cassert>',
        '#include <cctype>',
        '#include <cerrno>',
        '#include <cfloat>',
        '#include <ciso646>',
        '#include <climits>',
        '#include <clocale>',
        '#include <cmath>',
        '#include <csetjmp>',
        '#include <csignal>',
        '#include <cstdarg>',
        '#include <cstddef>',
        '#include <cstdio>',
        '#include <cstdlib>',
        '#include <cstring>',
        '#include <ctime>',
        '#include <ccomplex>',
        '#include <cfenv>',
        '#include <cinttypes>',
        '#include <cstdbool>',
        '#include <cstdint>',
        '#include <ctgmath>',
        '#include <cwchar>',
        '#include <cwctype>',
        '#include <algorithm>',
        '#include <bitset>',
        '#include <complex>',
        '#include <deque>',
        '#include <exception>',
        '#include <fstream>',
        '#include <functional>',
        '#include <iomanip>',
        '#include <ios>',
        '#include <iosfwd>',
        '#include <iostream>',
        '#include <istream>',
        '#include <iterator>',
        '#include <limits>',
        '#include <list>',
        '#include <locale>',
        '#include <map>',
        '#include <memory>',
        '#include <new>',
        '#include <numeric>',
        '#include <ostream>',
        '#include <queue>',
        '#include <set>',
        '#include <sstream>',
        '#include <stack>',
        '#include <stdexcept>',
        '#include <streambuf>',
        '#include <string>',
        '#include <typeinfo>',
        '#include <utility>',
        '#include <valarray>',
        '#include <vector>',
        '#include <array>',
        '#include <atomic>',
        '#include <chrono>',
        '#include <condition_variable>',
        '#include <forward_list>',
        '#include <future>',
        '#include <initializer_list>',
        '#include <mutex>',
        '#include <random>',
        '#include <ratio>',
        '#include <regex>',
        '#include <system_error>',
        '#include <thread>',
        '#include <tuple>',
        '#include <typeindex>',
        '#include <type_traits>',
        '#include <unordered_map>',
        '#include <unordered_set>',
        '#include <iostream>',
        '#include <iomanip>',
        'int main(void) {',
        '%s',
        'return 0;',
        '}',
      }, '\n')

      full_pred.cpp = function(lines)
        local joined = table.concat(lines, '\n')
        return joined:find '#include'
          and (joined:find 'int main' or joined:find 'void main')
      end
    end

    local function setup_c(config)
      config.c = {
        command = 'clang',
        tempfile = '%{tempname()}.c',
      }

      config.c['cmdopt'] = '-Wall -Wextra -std=c11'
      if env.is_win32 then
        config.c['exec'] = {
          '%c %o %s -o %s:p:r.exe',
          '%s:p:r.exe %a',
        }
        config.c['hook/sweep/files'] = { '%S:p:r.exe' }
      else
        config.c['exec'] = {
          '%c %o %s -o %s:p:r',
          '%s:p:r %a',
        }
        config.c['hook/sweep/files'] = { '%S:p:r' }
      end

      -- part_c
      config.part_c = deepcopy(config.c)
      config.part_c['hook/shebang/enable'] = 1
      config.part_c['hook/eval/enable'] = 1
      config.part_c['hook/eval/template'] = table.concat({
        '#include <stdio.h>',
        '#include <stdlib.h>',
        '#include <string.h>',
        'int main(void) {',
        '%s',
        'return 0;',
        '}',
      }, '\n')
    end

    local function setup_rust(config)
      config.rust = {
        command = 'rust-runner',
        exec = { '%c %s' },
        ['hook/shebang/enable'] = 0,
      }

      config.part_rust = deepcopy(config.rust)
      config.part_rust['hook/eval/enable'] = 1
      config.part_rust['hook/eval/template'] = 'fn main() {\n%s\n}'
      full_pred.rust = function(lines)
        local joined = table.concat(lines, '\n')
        return joined:find 'fn main()'
      end

      config.cargo = {
        command = 'cargo',
        exec = { '%c run' },
        ['hook/shebang/enable'] = 0,
      }
    end

    local function setup_python(config)
      if env.is_win32 then
        config.python = {
          ['hook/output_encode/encoding'] = 'sjis',
        }
      end
    end

    local function setup_typescript(config)
      local function quote(value)
        if env.is_win32 then
          return string.format('""%s""', value)
        else
          return string.format('\\"%s\\"', value)
        end
      end

      local compiler_options = {
        [quote 'target'] = quote 'es2017',
        [quote 'lib'] = '[' .. table.concat({
          quote 'dom',
          quote 'es2015',
          quote 'es5',
          quote 'es6',
          quote 'es2017',
        }, ', ') .. ']',
      }

      compiler_options = table
        .iter(compiler_options, pairs)
        :map(function(k, v)
          return k .. ': ' .. v
        end)
        :to_table()
      compiler_options = '"{ '
        .. table.concat(compiler_options, ', ')
        .. ' }"'

      local cmdopt = table.concat({
        '--compiler-options',
        compiler_options,
      }, ' ')

      config.tsnode = {
        exec = '%c %o %s',
        cmdopt = cmdopt,
        command = 'ts-node',
      }

      config.typescript = {
        exec = '%c run %o %s',
        cmdopt = '--allow-env --allow-read --allow-write --allow-net',
        command = 'deno',
      }
    end

    local function setup_racket(config)
      config.scheme = {
        command = 'racket',
        exec = '%c %s',
        ['hook/shebang/enable'] = 0,
      }
    end

    local function populate_config()
      local config = {
        _ = {
          runner = 'nvimterm',
          ['runner/nvimterm/vsplit_width'] = 100,
        },
      }

      setup_proass(config)
      setup_cpp(config)
      setup_c(config)
      setup_rust(config)
      setup_python(config)
      setup_typescript(config)
      setup_racket(config)

      return config
    end

    local function call_with_range(original_filetype, first, last)
      local bufnr = vim.api.nvim_get_current_buf()
      local lines = vim.api.nvim_buf_get_lines(bufnr, first, last, true)
      -- part_{filetype} ではなく {filetype} を使うべきかどうかを判断する
      local should_full = full_pred[original_filetype]
        or function(_)
          return false
        end
      local filetype
      if should_full(lines) then
        filetype = original_filetype
      else
        filetype = 'part_' .. original_filetype
        if vim.g.quickrun_config[filetype] == nil then
          -- part_ 用の設定がない場合は元々の設定で試す。
          filetype = original_filetype
        end
      end
      local quickrun_cmd =
        string.format(':%d,%dQuickRun %s', first + 1, last, filetype)
      vim.cmd(quickrun_cmd)
    end

    local function partial_markdown(first, last)
      -- 最低でも ```{lang}, ``` と中身の3行が必要。行数が少なすぎる場合は
      -- エラーとする。
      -- first, last は exclusive なことに注意
      if last - first < 3 then
        error(
          'The specified range is too short: '
            .. 'at least 3 lines are needed'
        )
        return
      end

      -- 言語判定
      local curr_buf = vim.api.nvim_get_current_buf()
      local marker = vim.api
        .nvim_buf_get_lines(curr_buf, first, first + 1, true)[1]
        :gsub('%s+', '')

      if marker:sub(1, 3) ~= '```' then
        error(
          'VISUAL region is not markdown snippet: ' .. 'not starting with ```'
        )
        return
      end

      local filetype = marker:sub(4)

      -- 最終行が ``` であるかを確認
      marker = vim.api.nvim_buf_get_lines(curr_buf, last - 1, last, true)[1]
      if marker ~= '```' then
        error(
          'VISUAL region is not markdown snippet: ' .. ' not ending with ```'
        )
        return
      end

      print('detected filetype: ' .. filetype)

      -- 呼び出す
      call_with_range(filetype, first + 1, last - 1)
    end

    local function partial_other(filetype, first, last)
      call_with_range(filetype, first, last)
    end

    local function partial_quickrun(first, last)
      -- zero-indexed, exclusive にする (Neovim API の仕様に合わせる)
      first = first - 1
      last = last

      local filetype = vim.opt.filetype:get()
      -- markdown, pandoc.markdown, etc
      if filetype:match 'markdown' then
        partial_markdown(first, last)
      else
        partial_other(filetype, first, last)
      end
    end

    -- 各言語ごとの設定を反映する
    vim.g.quickrun_config = populate_config()

    -- キーバインド

    -- 部分実行 QuickRun
    k.xno('<Plug>(partial-quickrun)', partial_quickrun, { range = true })

    -- バッファで実行
    k.n('<Leader>r', function()
      local kind = vim.b.quickrun_kind or vim.opt.filetype:get()
      return k.t(k.cmd(string.format('QuickRun %s', kind)))
    end, { expr = true })
    k.x('<Leader>r', '<Plug>(partial-quickrun)')
    k.n('<Leader>P', k.cmd 'QuickRun proass -runner system -outputter buffer')

    -- 種類を設定
    cmd.add('QuickRunSetKind', function(ctx)
      vim.b.quickrun_kind = ctx.args[1]
      msg.info('<Leader>r で :QuickRun %s を実行します', ctx.args[1])
    end, {
      nargs = '1',
      complete = require('rc.lib.completer_helper').create_completer_from_static_list(
        table
          .iter_keys(vim.g.quickrun_config, pairs)
          :filter(function(v)
            return v ~= '_'
          end)
          :to_table()
      ),
    })
  end,
}

use_as_deps 'statiolake/vim-quickrun-runner-nvimterm'

use {
  'statiolake/vim-junkfile',
  before_load = function()
    if vim.fn.executable 'workspace_path' ~= 0 then
      vim.g['junkfile#workspace_path'] = 'workspace_path -d'
      vim.g['junkfile#workspace_path_is_shell_command'] = 1
    else
      vim.g['junkfile#workspace_path'] = '~/junk/%Y/%m%d'
      vim.g['junkfile#workspace_path_is_shell_command'] = 0
    end

    k.n('<A-t>', ':<C-u>Junkfile ', { silent = false })
  end,
}

use {
  -- ソースコードを画像化するプラグイン (Rust 製 silicon に依存)
  'segeljakt/vim-silicon',
  before_load = function()
    vim.g.silicon = {
      theme = 'gruvbox',
      font = 'Consolas;Meiryo',
      background = '#282828',
      ['shadow-color'] = '#555555',
      ['line-pad'] = 2,
      ['pad-horiz'] = 20,
      ['pad-vert'] = 20,
      ['shadow-blur-radius'] = 0,
      ['shadow-offset-x'] = 0,
      ['shadow-offset-y'] = 0,
      ['line-number'] = false,
      ['round-corner'] = false,
      ['window-controls'] = false,
      output = vimfn.expand(
        '~/Pictures/silicon-{time:%Y-%m-%d-%H%M%S}.png',
        nil,
        nil
      ),
    }
  end,
}

local function skk_large_dictionary()
  local jisyo_cands = {
    env.path_under_data 'SKK-JISYO.L',
    '/usr/share/skk/SKK-JISYO.L',
  }
  for _, jisyo in ipairs(jisyo_cands) do
    if vim.fn.filereadable(jisyo) ~= 0 then
      return jisyo
    end
  end
  return '(skk large dictionary not found)'
end

local function skk_user_dictionary()
  local on_dropbox = vimfn.expand '~/Dropbox/.skkeleton'
  local on_home = vimfn.expand '~/.skkeleton'
  if vim.fn.filereadable(on_dropbox) ~= 0 then
    return on_dropbox
  else
    return on_home
  end
end

use {
  kind = manager.helper.local_if_exists,
  url = 'vim-skk/skkeleton',
  path = vimfn.expand '~/dev/github/skkeleton',
  enabled = cg 'editor.ime' == 'skkeleton',
  simple = true,
  depends = { 'denops.vim' },
  before_load = function()
    k.i('<C-j>', '<Plug>(skkeleton-enable)')
    k.c('<C-j>', '<Plug>(skkeleton-enable)')

    ac.augroup('rc__skkeleton_init', function(au)
      au('User', 'skkeleton-initialize-pre', function()
        vim.fn['skkeleton#register_kanatable']('rom', {
          ['v,'] = { ',', '' },
          ['v.'] = { '.', '' },
        })
        vim.fn['skkeleton#register_keymap']('input', '<C-j>', 'kakutei')
        vim.fn['skkeleton#config'] {
          ['markerHenkan'] = '@',
          ['markerHenkanSelect'] = '*',
          ['globalJisyo'] = skk_large_dictionary(),
          ['userJisyo'] = skk_user_dictionary(),
        }
      end)
    end)
  end,
}

use {
  'klen/nvim-config-local',
  simple = true,
  after_load = function()
    require('config-local').setup {
      config_files = {
        vimfn.expand '.vim/vimrc.lua',
        vimfn.expand '.vim/vimrc.vim',
      },
      hashfile = vim.fn.stdpath 'data' .. '/config-local',
      autocommands_create = true,
      commands_create = true,
      silent = false,
      lookup_parents = false,
    }
  end,
}

use {
  'jghauser/mkdir.nvim',
  simple = true,
}

use {
  'tyru/capture.vim',
  simple = true,
}

use {
  'Shatur/neovim-session-manager',
  depends = { 'plenary.nvim' },
  opt_depends = { 'telescope.nvim' },
  after_load = function()
    local path = require 'plenary.path'
    local session_config = require 'session_manager.config'
    local is_home_dir = vimfn.expand(vim.fn.getcwd()) == vimfn.expand '~'
    local autoload_mode = (cg 'editor.simpleMode' or is_home_dir)
        and session_config.AutoloadMode.Disabled
      or session_config.AutoloadMode.CurrentDir

    require('session_manager').setup {
      sessions_dir = path:new(vim.fn.stdpath 'data', 'sessions'),
      path_replacer = '__',
      colon_replacer = '++',
      autoload_mode = autoload_mode,
      autosave_last_session = true,
      autosave_ignore_not_normal = true,
      autosave_ignore_filetypes = {
        'gitcommit',
      },
      autosave_only_in_session = false,
      max_path_length = 80,
    }

    k.nno('<C-y>', k.cmd 'SessionManager load_session')
    k.nno('<C-A-y>', k.cmd 'SessionManager load_current_dir_session')
  end,
}

-- }}}
