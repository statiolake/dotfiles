local k = require 'rc.lib.keybind'
local vimfn = require 'rc.lib.vimfn'

return {
  {
    'tpope/vim-sleuth',
  },
  {
    'wsdjeg/vim-fetch',
    keys = { { 'gF', mode = { 'n', 'x' } } },
    init = function()
      k.nx('gf', 'gF')
    end,
  },
  {
    'tyru/open-browser.vim',
    keys = {
      { '<Plug>(openbrowser-open)', mode = { 'n', 'x' } },
      { '<Plug>(openbrowser-search)', mode = { 'n', 'x' } },
    },
    init = function()
      k.nx('gx', '<Plug>(openbrowser-open)')
      k.nx('g?', '<Plug>(openbrowser-search)')
    end,
  },
  {
    'statiolake/nvim-junkfile',
    cmd = 'Junkfile',
    init = function()
      k.n('<A-t>', ':<C-u>Junkfile ', { silent = false })
    end,
    config = function()
      local workspace_path
      if vim.fn.executable 'workspace_path' ~= 0 then
        workspace_path = vim.fn.trim(vim.fn.system 'workspace_path -d')
      else
        workspace_path = vimfn.expand '~/junk/%Y/%m%d'
      end

      require('junkfile').setup {
        workspace_path = workspace_path,
      }
    end,
  },
  {
    -- ソースコードを画像化するプラグイン (Rust 製 silicon に依存)
    'segeljakt/vim-silicon',
    cmd = 'Silicon',
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
    init = function()
      k.nno('<C-y>', k.cmd 'SessionManager load_session')
      k.nno('<C-A-y>', k.cmd 'SessionManager load_current_dir_session')
    end,
    config = function()
      local path = require 'plenary.path'
      local session_config = require 'session_manager.config'
      local is_home_dir = vimfn.expand(vim.fn.getcwd()) == vimfn.expand '~'
      local autoload_mode = is_home_dir
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
    'dstein64/vim-startuptime',
    cmd = 'StartupTime',
    init = function()
      vim.g.startuptime_tries = 10
    end,
  },
  -- {
  --   import = 'rc.lazy.general.individual.skkeleton',
  -- },
  {
    import = 'rc.lazy.general.individual.quickrun',
  },
}
