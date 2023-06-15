local k = require 'rc.lib.keybind'
local vimfn = require 'rc.lib.vimfn'
local cg = get_global_config

return {
  {
    'tpope/vim-sleuth',
  },
  {
    'wsdjeg/vim-fetch',
    keys = {
      'gf',
      mode = { 'n', 'x' },
      'gF',
    },
  },
  {
    'tyru/open-browser.vim',
    keys = {
      {
        'gx',
        mode = { 'n', 'x' },
        '<Plug>(openbrowser-open)',
      },
      {
        'g?',
        mode = { 'n', 'x' },
        '<Plug>(openbrowser-search)',
      },
    },
  },
  {
    'statiolake/vim-junkfile',
    init = function()
      if vim.fn.executable 'workspace_path' ~= 0 then
        vim.g['junkfile#workspace_path'] = 'workspace_path -d'
        vim.g['junkfile#workspace_path_is_shell_command'] = 1
      else
        vim.g['junkfile#workspace_path'] = '~/junk/%Y/%m%d'
        vim.g['junkfile#workspace_path_is_shell_command'] = 0
      end
      k.n('<A-t>', ':<C-u>Junkfile ', { silent = false })
    end,
  },
  {
    -- ソースコードを画像化するプラグイン (Rust 製 silicon に依存)
    'segeljakt/vim-silicon',
    init = function()
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
  },
  {
    'klen/nvim-config-local',
    opts = {
      config_files = {
        vimfn.expand '.vim/vimrc.lua',
        vimfn.expand '.vim/vimrc.vim',
      },
      hashfile = vim.fn.stdpath 'data' .. '/config-local',
      autocommands_create = true,
      commands_create = true,
      silent = false,
      lookup_parents = false,
    },
  },
  {
    'jghauser/mkdir.nvim',
  },
  {
    'Shatur/neovim-session-manager',
    dependencies = {
      'plenary.nvim',
      'telescope.nvim',
    },
    keys = {
      { '<C-y>', k.cmd 'SessionManager load_session' },
      { '<C-A-y>', k.cmd 'SessionManager load_current_dir_session' },
    },
    config = function()
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
        autosave_ignore_buftypes = {
          'terminal',
        },
        autosave_only_in_session = false,
        max_path_length = 80,
      }
    end,
  },
  {
    import = 'rc.lazy.general.individual.skkeleton',
  },
  {
    import = 'rc.lazy.general.individual.quickrun',
  },
}
