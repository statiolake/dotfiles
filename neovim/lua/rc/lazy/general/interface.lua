local cmd = require 'rc.lib.command'
local vimfn = require 'rc.lib.vimfn'
local k = require 'rc.lib.keybind'
local ac = require 'rc.lib.autocmd'
local env = require 'rc.lib.env'
local colorset = require 'rc.lib.colorset'
local hi = require 'rc.lib.highlight'
local c = require 'rc.config'

return {
  {
    'equalsraf/neovim-gui-shim',
  },
  {
    'alvarosevilla95/luatab.nvim',
    dependencies = pack {
      when(c.use_icons, 'nvim-web-devicons'),
    },
    event = 'VeryLazy',
    config = function()
      local opts = {}
      if not c.use_icons then
        opts.devicon = function()
          return ''
        end
      end
      require('luatab').setup(opts)
    end,
  },
  {
    'simnalamburt/vim-mundo',
    cmd = 'MundoToggle',
    init = function()
      k.nno('<A-z>', k.cmd 'MundoToggle')
    end,
  },
  {
    't9md/vim-quickhl',
    keys = {
      '<Plug>(quickhl-manual-this-whole-word)',
      { '<Plug>(quickhl-manual-this)', mode = 'x' },
      { '<Plug>(quickhl-manual-clear)', mode = { 'n', 'x' } },
      { '<Plug>(quickhl-manual-reset)', mode = { 'n', 'x' } },
    },
    cmd = {
      'NoQuickHl',
    },
    init = function()
      k.n('+', '<Plug>(quickhl-manual-this-whole-word)')
      k.x('+', '<Plug>(quickhl-manual-this)')
      k.nx('-', '<Plug>(quickhl-manual-clear)')
      k.nx('<Leader>M', '<Plug>(quickhl-manual-reset)')
      cmd.add('NoQuickHl', vim.fn['quickhl#manual#reset'])
    end,
  },
  {
    'voldikss/vim-floaterm',
    cmd = 'FloatermNew',
    init = function()
      local function extract(cb)
        -- border は { char, highlight } のリストということもある
        return cb[1] or cb
      end
      vim.g.floaterm_borderchars = {
        extract(c.border[2]),
        extract(c.border[4]),
        extract(c.border[6]),
        extract(c.border[8]),
        extract(c.border[1]),
        extract(c.border[3]),
        extract(c.border[5]),
        extract(c.border[7]),
      }
      colorset.register_editor_colorscheme_hook(function()
        hi.link('FloatermBorder', 'FloatBorder')
      end)
      local keys = { '<C-@>', '<C-\\>' }
      for _, key in ipairs(keys) do
        k.add({ 'n', 't' }, key, function()
          require('lazy').load { plugins = { 'vim-floaterm' } }
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
  },
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = pack {
      'lush.nvim',
      when(c.ide == 'builtin', 'nvim-navic'),
    },
    config = function()
      local stl = require 'rc.lib.statusline'

      local theme = colorset.get(c.colorset).lualine
      if type(theme) == 'function' then
        theme = theme()
      end

      require('lualine').setup {
        options = {
          icons_enabled = c.use_icons,
          theme = theme,
          component_separators = '│',
          section_separators = c.use_icons
              and { left = '', right = '' }
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
                modified = c.use_icons and '' or '~',
                removed = '-',
              },
            },
            'diagnostics',
          },
          lualine_c = pack {
            {
              'filename',
              symbols = {
                modified = c.use_icons and ' ' or '[+]',
                readonly = c.use_icons and ' ' or '[-]', -- Text to show when the file is non-modifiable or readonly.
                unnamed = '(untitled)',
              },
            },
            stl.symbol_line,
          },
          lualine_x = {
            function()
              return stl.lsp_status(false)
            end,
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
    end,
  },
  {
    'kyazdani42/nvim-tree.lua',
    dependencies = pack {
      when(c.use_icons, 'nvim-web-devicons'),
    },
    cmd = 'NvimTreeToggle',
    init = function()
      k.nno('<C-b>', k.cmd 'NvimTreeToggle')
    end,
    config = function()
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
        k.n(
          'O',
          api.node.open.no_window_picker,
          opts 'Open: No Window Picker'
        )
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
        k.n('<C-CR>', api.tree.change_root_to_node, opts 'CD')
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

      cmd.add('NvimTreeChangeToCwd', function()
        require('nvim-tree.lib').change_dir(vimfn.expand('%:h', nil, nil))
      end)

      require('nvim-tree').setup {
        on_attach = on_attach,
        disable_netrw = true,
        hijack_netrw = true,
        reload_on_bufenter = true,
        update_cwd = true,
        diagnostics = {
          enable = true,
          icons = c.signs.diagnostics,
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
              file = c.use_icons,
              folder_arrow = c.use_icons,
            },
            glyphs = {
              git = {
                unstaged = c.use_icons and '' or '~',
                staged = c.use_icons and '' or '@',
                unmerged = c.use_icons and '' or '!',
                renamed = c.use_icons and '' or '>',
                untracked = c.use_icons and '' or '+',
                deleted = c.use_icons and '' or '-',
                ignored = c.use_icons and '◌' or '_',
              },
              folder = {
                default = c.use_icons and '' or '+',
                open = c.use_icons and '' or '~',
                empty = c.use_icons and '' or '+',
                empty_open = c.use_icons and '' or '+',
                symlink = c.use_icons and '' or 'L',
                symlink_open = c.use_icons and '' or 'L',
              },
            },
          },
        },
      }
    end,
  },
  {
    'sindrets/diffview.nvim',
    dependencies = { 'plenary.nvim' },
    cmd = 'DiffviewOpen',
    opts = {
      icons = { -- Only applies when use_icons is true.
        folder_closed = '',
        folder_open = '',
      },
      signs = {
        fold_open = c.use_icons and '' or '~',
        fold_closed = c.use_icons and '' or '+',
      },
      use_icons = c.use_icons,
    },
  },
}
