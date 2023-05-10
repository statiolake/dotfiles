local manager = require 'rc.lib.plugin_manager'
local use, use_as_deps = manager.use, manager.use_as_deps
local cmd = require 'rc.lib.command'
local msg = require 'rc.lib.msg'
local env = require 'rc.env'
local ac = require 'rc.lib.autocmd'
local k = require 'rc.lib.keybind'
local vimfn = require 'rc.lib.vimfn'
local cg = get_global_config

local completion = cg 'editor.ide.builtin.completion'
local selector = cg 'editor.ide.builtin.selector'

-- formatexpr を修正する {{{
-- Hack: https://github.com/neovim/neovim/pull/19677 に対応する
-- とんでもないデフォルト値を設定してくれたもんだな...
ac.augroup('rc__fix_formatexpr', function(au)
  au('LspAttach', '*', function()
    vim.opt_local.formatexpr = ''
  end)
end)
-- }}}

use {
  'neovim/nvim-lspconfig',
  depends = pack {
    when(selector == 'telescope', 'telescope.nvim'),
    when(selector == 'fzf', 'fzf-lsp.nvim'),
    'lsp-status.nvim',
    'neodev.nvim',
    'rust-tools.nvim',
    'nvim-lsp-ts-utils',
    'nvim-jdtls',
    -- mason-lspconfig を先に読み込む。そうしろって
    -- https://github.com/williamboman/mason-lspconfig.nvim にも書いてある
    'mason-lspconfig.nvim',
    when(completion == 'nvim-cmp', 'cmp-nvim-lsp'),
  },
  opt_depends = {
    'nvim-navic',
    'vim-illuminate',
    'nvim-config-local',
    'nvim-config-local',
    'fidget.nvim',
  },
  after_load = function()
    --vim.lsp.set_log_level 'trace'

    vim.opt.updatetime = 1000

    -- キーバインド {{{
    local function definition()
      if vim.opt.filetype:get() == 'help' then
        vim.api.nvim_feedkeys('K', 'n', true)
      else
        vim.lsp.buf.definition()
        --require('telescope.builtin').lsp_definitions()
      end
    end

    local function definition_vsplit()
      vim.cmd 'vsplit'
      definition()
    end

    if selector == 'telescope' then
      local telescope = require 'telescope.builtin'
      k.nno('g0', telescope.lsp_document_symbols)
      k.nno('gw', telescope.lsp_dynamic_workspace_symbols)
      k.nno('gp', telescope.diagnostics)
      k.nno('gr', telescope.lsp_references)
      k.nno('gD', telescope.lsp_implementations)
      k.nno('1gD', telescope.lsp_type_definitions)
    else
      local fzf_lsp = require 'fzf_lsp'
      k.nno('g0', fzf_lsp.document_symbol_call)
      k.nno('gw', fzf_lsp.workspace_symbol_call)
      k.nno('gp', fzf_lsp.diagnostic_call)
      k.nno('gr', fzf_lsp.references_call)
      k.nno('gD', fzf_lsp.implementation_call)
      k.nno('1gD', fzf_lsp.type_definition_call)
    end

    k.nno('g.', vim.lsp.buf.code_action)
    k.xno('g.', function()
      vim.lsp.buf.code_action { range = vim.lsp.util.compute_range }
    end)

    k.nno('gR', vim.lsp.buf.rename)
    k.nno('gh', vim.lsp.buf.hover)
    k.nno('K', vim.lsp.buf.hover)
    k.nno('go', definition)
    k.nno('gO', definition_vsplit)
    k.nno('gd', vim.diagnostic.open_float)
    k.nno('<C-n>', vim.diagnostic.goto_next)
    k.nno('<C-p>', vim.diagnostic.goto_prev)
    -- }}}

    -- サインのアイコンを変更する {{{
    local kind_map = {
      error = 'Error',
      warning = 'Warn',
      info = 'Info',
      hint = 'Hint',
    }
    local signs = cg 'ui.signs'
    for kind, sign in pairs(signs.diagnostics) do
      local hl = 'DiagnosticSign' .. kind_map[kind]
      vim.fn.sign_define(hl, { text = sign, texthl = hl, numhl = '' })
    end
    -- }}}

    -- floating window を設定する {{{
    local border = cg 'ui.border'
    vim.diagnostic.config {
      float = {
        border = border,
      },
    }
    -- }}}

    -- 独自のハンドラを登録する {{{
    local handler = require 'rc.lib.lsp_custom_handler'
    handler.enable_multi_server_hover()
    handler.enable_multi_server_signature_help()
    --handler.disable_diagnostics_virtual_text()
    -- }}}

    -- サーバー設定 {{{
    local mason_lspconfig = require 'mason-lspconfig'
    local lspconfig = require 'lspconfig'
    local settings = cg 'lsp'

    -- デフォルトオプションの設定 {{{

    local default_config = lspconfig.util.default_config

    -- ステータスバー {{{
    if not manager.tap 'fidget.nvim' then
      local lsp_status = require 'lsp-status'

      -- ステータスライン用に capability を更新する
      lsp_status.config {
        -- Diagnostics は Lualine で表示されるのでいらない
        diagnostics = false,
        indicator_errors = 'E',
        indicator_warnings = 'W',
        indicator_info = 'I',
        indicator_hint = 'H',
        indicator_ok = 'OK',
        --spinner_frames = { '|', '/', '-', '\\' },
        spinner_frames = { '.', 'o', 'O', '@', '*', ' ' },
        -- spinner_frames = {
        --   '⣾',
        --   '⣽',
        --   '⣻',
        --   '⢿',
        --   '⡿',
        --   '⣟',
        --   '⣯',
        --   '⣷',
        -- },
        status_symbol = '',
      }

      -- window/workDoneProgress などを追加する
      lsp_status.register_progress()
      table.in_place_deep_extend(
        default_config.capabilities,
        lsp_status.capabilities
      )
    end
    -- }}}

    -- 補完 {{{
    -- nvim-cmp
    if completion == 'nvim-cmp' then
      table.in_place_deep_extend(
        default_config.capabilities,
        require('cmp_nvim_lsp').default_capabilities()
      )
    else
      -- 他
      table.in_place_deep_extend(default_config.capabilities, {
        textDocument = {
          completion = { completionItem = { snippetSupport = true } },
        },
      })
    end
    -- }}}

    default_config.autostart = true

    -- detached = true がデフォルトだが true にしておくと一部の LSP を Windows
    -- で使ったときにコマンドプロンプト画面が表示されて stdin がうまくわたらな
    -- い問題があるっぽい
    default_config.detached = false

    -- illuminate, navic を設定
    default_config.on_attach = function(client, bufnr)
      local ok, illuminate, navic
      ok, illuminate = pcall(require, 'illuminate')
      if ok then
        illuminate.on_attach(client, bufnr)
      end

      ok, navic = pcall(require, 'nvim-navic')
      if ok then
        navic.attach(client, bufnr)
      end

      -- semantic tokens を無効化する
      --client.server_capabilities.semanticTokensProvider = nil
    end
    -- }}}

    -- 個別設定 {{{
    local function configure_servers()
      local use_icons = cg 'ui.useIcons'

      mason_lspconfig.setup_handlers {
        function(server_name) -- デフォルト
          lspconfig[server_name].setup {
            settings = settings[server_name] or {},
          }
        end,

        lua_ls = function()
          lspconfig.lua_ls.setup {
            settings = settings.lua_ls or {},
          }
        end,

        rust_analyzer = function()
          require('rust-tools').setup {
            tools = {
              inlay_hints = {
                auto = false,
                parameter_hints_prefix = use_icons and '  ' or ' <- ',
                other_hints_prefix = use_icons and ' • ' or ' >> ',
                highlight = 'NonText',
              },
              hover_actions = {
                border = cg 'ui.border',
              },
            },
            server = {
              standalone = true,
              cmd = when(env.is_win32, { 'cmd', '/c', 'rust-analyzer' }),
              settings = settings.rust_analyzer or {},
            },
          }
        end,

        tsserver = function()
          local ts_utils = require 'nvim-lsp-ts-utils'
          lspconfig.tsserver.setup {
            autostart = lspconfig.util.default_config.autostart
              and require('rc.lib.typescript_detector').opened_node_project(),
            init_options = ts_utils.init_options,
            settings = settings.tsserver or {},
            on_attach = function(client, bufnr)
              local _ = bufnr
              ts_utils.setup {
                inlay_hints_highlight = 'NonText',
              }
              ts_utils.setup_client(client)
            end,
          }
        end,

        denols = function()
          lspconfig.denols.setup {
            single_file_support = true,
            settings = settings.denols or {},
            autostart = lspconfig.util.default_config.autostart
              and not require('rc.lib.typescript_detector').opened_node_project(),
          }
        end,

        clangd = function()
          lspconfig.clangd.setup {
            handlers = (function()
              local ok, lsp_status = pcall(require, 'lsp-status')
              if not ok then
                return nil
              end
              return lsp_status.extensions.clangd.setup()
            end)(),
            single_file_support = true,
            settings = settings.clangd or {},
          }
        end,
      }
    end

    if manager.tap 'nvim-config-local' then
      -- もし klen/nvim-config-local がインストールされているのなら、その設定
      -- が終わってから読み込むことにする (プロジェクトローカルなオプションを
      -- 反映してから読み込みたいため)
      ac.augroup('rc__lsp_after_config', function(au)
        au('User', 'ConfigLocalFinished', function()
          configure_servers()
        end)
      end)
    else
      -- ローカルな vimrc を読み込む機能がない場合は今すぐ設定する
      configure_servers()
    end

    -- nvim-jdtls {{{
    ac.augroup('rc__nvim_jdtls', function(au)
      au('FileType', 'java', function()
        local jvm_arg = {}
        local jar_path = vimfn.expand(
          vim.fn.stdpath 'data'
            .. '/lsp_servers/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'
        )
        local configuration = vimfn.expand(
          vim.fn.stdpath 'data'
            .. '/lsp_servers/jdtls/config_'
            .. (env.is_win32 and 'win' or 'linux') -- FIXME: Mac
        )
        local java_cmd = pack {
          'java',
          '-Declipse.application=org.eclipse.jdt.ls.core.id1',
          '-Dosgi.bundles.defaultStartLevel=4',
          '-Declipse.product=org.eclipse.jdt.ls.core.product',
          '-Dosgi.checkConfiguration=true',
          '-Dosgi.sharedConfiguration.area=' .. configuration,
          '-Dosgi.sharedConfiguration.area.readOnly=true',
          '-Dosgi.configuration.cascaded=true',
          '-noverify',
          '-Xms1G',
          '--add-modules=ALL-SYSTEM',
          '--add-opens',
          'java.base/java.util=ALL-UNNAMED',
          '--add-opens',
          'java.base/java.lang=ALL-UNNAMED',
          unpack(jvm_arg),
          '-jar',
          jar_path,
          '-configuration',
          configuration,
          '-data',
          vimfn.expand(
            vim.fn.stdpath 'cache'
              .. '/jdtls-workspace/'
              .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
          ),
        }

        require('jdtls').start_or_attach {
          -- The command that starts the language server
          -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
          cmd = java_cmd,

          -- Here you can configure eclipse.jdt.ls specific settings
          -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
          -- for a list of options
          settings = settings.jdtls or {},

          -- Language server `initializationOptions`
          -- You need to extend the `bundles` with paths to jar files
          -- if you want to use additional eclipse.jdt.ls plugins.
          --
          -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
          --
          -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
          init_options = {
            bundles = {},
          },
          -- This starts a new client & server,
          -- or attaches to an existing client & server depending on the `root_dir`.
        }
      end)
    end)
    -- }}}

    -- 管理コマンド {{{

    -- 上書きしないといけないので後で実行する
    local configs = require 'lspconfig.configs'
    ac.augroup('rc__lsp_manage_cmd', function(au)
      au('VimEnter', '*', function()
        cmd.add('LspStart', function(ctx)
          local name = ctx.args[1]
          if name and name ~= '' then
            if configs[name] then
              configs[name].launch()
            else
              msg.error('unknown config: %s', name)
            end
          else
            msg.error 'please specify config name'
          end
        end, { nargs = '?' })

        cmd.add('LspStop', function(ctx)
          local function stop(client)
            client.stop(ctx.bang)
          end

          local idstr = ctx.args[1]
          if idstr then
            local id = vim.fn.str2nr(idstr)
            local client = vim.lsp.get_client_by_id(id)
            if client then
              stop(client)
            else
              msg.error("'%s' is not a valid client id", idstr)
            end
          else
            for _, client in ipairs(vim.lsp.get_active_clients()) do
              stop(client)
            end
          end
        end, { nargs = '?', bang = true })

        cmd.add('LspRestart', function(ctx)
          local function restart(client)
            client.stop(ctx.bang)
            local config = configs[client.name]
            if config then
              vim.defer_fn(config.launch, 500)
            end
          end

          local idstr = ctx.args[1]
          if idstr then
            local id = vim.fn.str2nr(idstr)
            local client = vim.lsp.get_client_by_id(id)
            if client then
              restart(client)
            else
              msg.error("'%s' is not a valid client id", idstr, id)
            end
          else
            for _, client in ipairs(vim.lsp.get_active_clients()) do
              restart(client)
            end
          end
        end, { nargs = '?', bang = true })
      end)
    end)
    -- }}}

    -- 追加機能コマンド {{{
    cmd.add('LspFormat', function()
      -- null-ls とかある現状だとフィルタリングなしで呼び出すのは厳しそうだ
      -- けど
      vim.lsp.buf.format {}
    end)

    cmd.add('LspRangeFormat', function(ctx)
      vim.lsp.buf.range_formatting({}, ctx.range.first, ctx.range.last)
    end, { range = true })
    -- }}}

    -- }}}

    -- }}}
  end,
}

use {
  'jose-elias-alvarez/null-ls.nvim',
  opt_depends = {
    -- mason があるならそれを先に読み込む。そうしろって
    -- https://github.com/jayp0521/mason-null-ls.nvim に書いてある。
    'mason.nvim',
  },
  after_load = function()
    local null_ls = require 'null-ls'

    local function configure_sources()
      local source_configs = cg 'nullLs.sources'
      local sources = {}
      for _, config in pairs(source_configs) do
        local kind, name = unpack(vim.split(config.base, '%.'))
        local base_source = null_ls.builtins[kind][name]
        table.insert(
          sources,
          base_source.with {
            filetypes = config.filetypes,
            condition = config.confition,
            command = config.command,
            args = config.args,
            extra_args = config.extraArgs,
          }
        )
      end

      null_ls.setup {
        debug = true,
        sources = sources,
      }
    end

    if manager.tap 'nvim-config-local' then
      -- もし klen/nvim-config-local がインストールされているのなら、その設定
      -- が終わってから読み込むことにする (プロジェクトローカルなオプションを
      -- 反映してから読み込みたいため)
      ac.augroup('rc__null_ls_after_config', function(au)
        au('User', 'ConfigLocalFinished', function()
          configure_sources()
        end)
      end)
    else
      -- ローカルな vimrc を読み込む機能がない場合は今すぐ設定する
      configure_sources()
    end
  end,
}

use {
  'williamboman/mason.nvim',
  after_load = function()
    local use_icons = cg 'ui.useIcons'

    require('mason').setup {
      ui = {
        border = cg 'ui.border',
        icons = {
          package_installed = use_icons and '' or '*',
          package_uninstalled = use_icons and '' or '-',
          package_pending = use_icons and '' or '+',
        },
      },
    }
  end,
}

use {
  'williamboman/mason-lspconfig.nvim',
  depends = { 'mason.nvim' },
  after_load = function()
    -- nvim-lspconfig がロード可能になってから nvim-lspconfig の setup() が呼
    -- び出される前に実行する必要があるらしいとのこと。したがって
    -- nvim-lspconfig が packadd されてから after_load が実行されるまでの間に
    -- 呼び出す必要がある。
    -- FIXME: もっとましな順序付けはないのか
    manager.hook_after_load_pre('nvim-lspconfig', function()
      require('mason-lspconfig').setup()
    end)
  end,
}

use {
  'jayp0521/mason-null-ls.nvim',
  depends = { 'mason.nvim', 'null-ls.nvim' },
  after_load = function()
    require('mason-null-ls').setup()
  end,
}

use_as_deps {
  'folke/neodev.nvim',
  after_load = function()
    -- Hack: neodev.nvim は root_dir が stdpath('config') に含まれるか
    -- stdpath('config') が root_dir に含まれるかのどちらかの場合にしか依存ラ
    -- イブラリをロードしてくれないみたい。しかしそれは都合が悪いので修正する。
    -- FIXME: 内部を直接いじるので neodev の改装で一発で壊れうる。
    --
    -- see also: <https://github.com/folke/neodev.nvim/blob/7f8b73f56d2055efb3b0550a92d62ea78b1e5e41/lua/neodev/util.lua#L31-L33>

    -- せめてもの抵抗として一応当該関数が存在することは確認しておく。
    local util = require 'neodev.util'
    if type(util.is_nvim_config) == 'function' then
      -- 存在する場合は上書きする。root_dir は dotfiles になるはず。
      util.is_nvim_config = function(root_dir)
        return vim.fn.fnamemodify(root_dir, ':t') == 'dotfiles'
      end
    else
      -- 存在しない場合はたぶんアップデートでこの辺が改装されたんだろう。メッ
      -- セージを表示して何とか気づけるようにしておく。関数自体が削除されてい
      -- ないけど使われなくなったような場合は... 知らない。
      msg.error 'neodev.util.is_nvim_config() no longer exists'
    end

    -- nvim-lspconfig がロード可能になってから nvim-lspconfig の setup() が呼
    -- び出される前に実行する必要があるらしいとのこと。したがって
    -- nvim-lspconfig が packadd されてから after_load が実行されるまでの間に
    -- 呼び出す必要がある。
    -- FIXME: もっとましな順序付けはないのか
    manager.hook_after_load_pre('nvim-lspconfig', function()
      require('neodev').setup { runtime_path = true }
    end)
  end,
}

use_as_deps 'simrat39/rust-tools.nvim'

use_as_deps 'jose-elias-alvarez/nvim-lsp-ts-utils'

use_as_deps 'mfussenegger/nvim-jdtls'

use 'nvim-lua/lsp-status.nvim'

use 'RRethy/vim-illuminate'

use {
  'SmiteshP/nvim-navic',
  after_load = function()
    -- 遅延ロード
    ac.on_vim_started(function()
      local use_icons = get_global_config 'ui.useIcons'
      require('nvim-navic').setup {
        icons = {
          File = use_icons and ' ' or '[FILE] ',
          Module = use_icons and ' ' or '[MOD] ',
          Namespace = use_icons and ' ' or '[NS] ',
          Package = use_icons and ' ' or '[PKG] ',
          Class = use_icons and ' ' or '[C] ',
          Method = use_icons and ' ' or '[M] ',
          Property = use_icons and ' ' or '[P] ',
          Field = use_icons and ' ' or '[V] ',
          Constructor = use_icons and ' ' or '[CTOR] ',
          Enum = use_icons and '練' or '[E] ',
          Interface = use_icons and '練' or '[IF] ',
          Function = use_icons and ' ' or '[F] ',
          Variable = use_icons and ' ' or '[V] ',
          Constant = use_icons and ' ' or '[CONST] ',
          String = use_icons and ' ' or '[S] ',
          Number = use_icons and ' ' or '[I] ',
          Boolean = use_icons and '◩ ' or '[B] ',
          Array = use_icons and ' ' or '[A] ',
          Object = use_icons and ' ' or '[O] ',
          Key = use_icons and ' ' or '[K] ',
          Null = use_icons and 'ﳠ ' or '[N] ',
          EnumMember = use_icons and ' ' or '[EM] ',
          Struct = use_icons and ' ' or '[C] ',
          Event = use_icons and ' ' or '[EV] ',
          Operator = use_icons and ' ' or '[OP] ',
          TypeParameter = use_icons and ' ' or '[T] ',
        },
      }
    end)
  end,
}

if completion == 'nvim-cmp' then
  require 'rc.part.plugin.rc.part.plugin.builtin.cmp'
end

if completion == 'ddc' then
  require 'rc.part.plugin.builtin.ddc'
end

use_as_deps {
  'hrsh7th/vim-vsnip',
  before_load = function()
    vim.g.vsnip_snippet_dir = env.path_under_config '.vsnip'
  end,
}

use_as_deps 'hrsh7th/vim-vsnip-integ'

use_as_deps 'hrsh7th/cmp-vsnip'

use_as_deps {
  'SirVer/ultisnips',
  depends = { 'vim-snippets', 'vim-emmet-ultisnips' },
  before_load = function()
    vim.g.UltiSnipsSnippetStorageDirectoryForUltiSnipsEdit =
      env.path_under_config 'ultisnips'
    vim.g.UltiSnipsSnippetDirectories = { 'ultisnips' }

    vim.g.UltiSnipsEditSplit = 'context'

    -- マッピングは補完エンジン側でやる
    vim.g.UltiSnipsExpandTrigger = '<NUL>'
    vim.g.UltiSnipsJumpForwardTrigger = '<NUL>'
    vim.g.UltiSnipsJumpBackwardTrigger = '<NUL>'
    vim.g.UltiSnipsRemoveSelectModeMappings = 0
  end,
  after_load = function()
    ac.augroup('rc__unregister_ultisnips_autotrigger', function(au)
      au('VimEnter', '*', function()
        vim.cmd [[autocmd! UltiSnips_AutoTrigger]]
      end)
    end)
  end,
}

use_as_deps 'honza/vim-snippets'

use_as_deps 'adriaanzon/vim-emmet-ultisnips'

-- E303 により signature help やポップアップが表示されない問題の修正
local function disable_swap_on_vs_vim_buffer()
  ac.augroup('rc__disable_swap_on_vs_vim_buffer', function(au)
    au('BufAdd', 'VS.Vim.Buffer*', function()
      -- 追加されたバッファの番号を取得
      local bufnr =
        inspect(vim.fn.bufnr(vimfn.expand('<afile>', false, false)))
      if bufnr >= 0 then
        vim.api.nvim_buf_set_option(bufnr, 'swapfile', false)
      end
    end)
  end)
end

use {
  'matsui54/denops-signature_help',
  depends = { 'denops.vim' },
  before_load = function()
    local cfg_border = cg 'ui.border'
    vim.g.signature_help_config = {
      border = cfg_border
        and cfg_border[1]
        and (cfg_border[1][1] or cfg_border[1]) ~= ' ',
      style = 'virtual',
      multiLabel = true,
    }
    require('rc.lib.colorset').register_editor_colorscheme_hook(function()
      vim.cmd [[
          hi! link SignatureHelpVirtual Comment
          hi! link LspSignatureActiveParameter Special
        ]]
    end)
    disable_swap_on_vs_vim_buffer()
  end,
  after_load = function()
    vim.fn['signature_help#enable']()
  end,
}

-- これを有効にすると何故か補完候補表示中にちょくちょく中止されてしまうので無
-- 効にしておく (たぶん pum.vim なら大丈夫なんだろうけど)
-- use {
--   'matsui54/denops-popup-preview.vim',
--   depends = { 'denops.vim' },
--   before_load = function()
--     disable_swap_on_vs_vim_buffer()
--   end,
--   after_load = function()
--     vim.fn['popup_preview#enable']()
--   end,
-- }

-- use {
--   'ray-x/lsp_signature.nvim',
--   after_load = function()
--     require('lsp_signature').setup {
--       bind = true,
--       handler_opts = {
--         border = cg'ui.border',
--       },
--       -- 自動的にトリガーする
--       floating_window = true,
--       hint_enable = false,
--       hint_prefix = '^ ',
--       always_trigger = true,
--       extra_trigger_chars = {},
--       toggle_key = '<M-i>',
--     }
--   end,
-- }

-- なぜかステータスラインの描画を壊すので無効化する
-- use {
--   'j-hui/fidget.nvim',
--   after_load = function()
--     require('fidget').setup {}
--   end,
-- }

use {
  'folke/trouble.nvim',
  after_load = function()
    local use_icons = cg 'ui.useIcons'
    require('trouble').setup {
      icons = use_icons,
      fold_open = use_icons and '' or '~',
      fold_closed = use_icons and '' or '+',
      signs = (cg 'ui.signs').diagnostics,
    }

    k.nno('<A-m>', k.cmd 'TroubleToggle')
  end,
}
