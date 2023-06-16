local env = require 'rc.lib.env'
local ac = require 'rc.lib.autocmd'
local k = require 'rc.lib.keybind'
local vimfn = require 'rc.lib.vimfn'
local msg = require 'rc.lib.msg'
local cmd = require 'rc.lib.command'
local c = require 'rc.config'

local lsp_settings = {
  pyright = {
    python = {
      analysis = {
        diagnosticMode = 'workspace',
        typeCheckingMode = 'basic',
      },
    },
  },
  rust_analyzer = {
    ['rust-analyzer'] = {
      assist = {
        importEnforceGranularity = true,
        importGranularity = 'crate',
      },
      callInfo = {
        full = true,
      },
      checkOnSave = {
        command = 'clippy',
      },
      procMacro = {
        enable = true,
      },
      rustfmt = {
        overrideCommand = {
          'cargo',
          'clippy',
          '--workspace',
          '--message-format=json',
          '--all-targets',
        },
      },
    },
  },
  lua_ls = {
    Lua = {
      IntelliSense = {
        traceBeSetted = true,
        traceFieldInject = true,
        traceLocalSet = true,
        traceReturn = true,
      },
      completion = {
        callSnippet = 'Both',
      },
    },
  },
  gopls = {
    gopls = {
      staticcheck = true,
      analyses = {
        ST1000 = false,
        ST1003 = true,
        ST1016 = false,
        ST1020 = false,
        ST1021 = false,
        ST1022 = true,
        ST1023 = true,
      },
    },
  },
}

return {
  {
    'neovim/nvim-lspconfig',
    dependencies = pack {
      'telescope.nvim',
      'lsp-status.nvim',
      'neodev.nvim',
      'rust-tools.nvim',
      'nvim-lsp-ts-utils',
      'nvim-jdtls',
      'mason.nvim',
      'mason-lspconfig.nvim',
      'cmp-nvim-lsp',
      'nvim-navic',
      'vim-illuminate',
      'nvim-config-local',
      'nvim-config-local',
      'fidget.nvim',
      'null-ls.nvim',
    },
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
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

      local telescope = require 'telescope.builtin'
      k.nno('g0', telescope.lsp_document_symbols)
      k.nno('gw', telescope.lsp_dynamic_workspace_symbols)
      k.nno('gp', telescope.diagnostics)
      k.nno('gr', telescope.lsp_references)
      k.nno('gD', telescope.lsp_implementations)
      k.nno('1gD', telescope.lsp_type_definitions)

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
      local signs = c.signs
      for kind, sign in pairs(signs.diagnostics) do
        local hl = 'DiagnosticSign' .. kind_map[kind]
        vim.fn.sign_define(hl, { text = sign, texthl = hl, numhl = '' })
      end
      -- }}}

      -- floating window を設定する {{{
      local border = c.border
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

      -- デフォルトオプションの設定 {{{

      local default_config = lspconfig.util.default_config

      -- ステータスバー {{{
      local ok, _ = require 'fidget'
      -- fidget がないときだけ
      if not ok then
        local lsp_status = require 'lsp-status'

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
      table.in_place_deep_extend(
        default_config.capabilities,
        require('cmp_nvim_lsp').default_capabilities()
      )
      -- }}}

      default_config.autostart = true

      -- detached = true がデフォルトだが true にしておくと一部の LSP を Windows
      -- で使ったときにコマンドプロンプト画面が表示されて stdin がうまくわたらな
      -- い問題があるっぽい
      default_config.detached = false

      -- illuminate, navic を設定
      default_config.on_attach = function(client, bufnr)
        local illuminate, navic
        ok, illuminate = pcall(require, 'illuminate')
        if ok then
          illuminate.on_attach(client, bufnr)
        end

        -- navic は documentSymbolProvider が有効なときにのみ利用する
        if client.server_capabilities.documentSymbolProvider then
          ok, navic = pcall(require, 'nvim-navic')
          if ok then
            navic.attach(client, bufnr)
          end
        end

        -- semantic tokens を無効化する
        --client.server_capabilities.semanticTokensProvider = nil
      end
      -- }}}

      -- 個別設定 {{{
      local function configure_servers()
        mason_lspconfig.setup_handlers {
          function(server_name) -- デフォルト
            lspconfig[server_name].setup {
              settings = lsp_settings[server_name] or {},
            }
          end,

          lua_ls = function()
            lspconfig.lua_ls.setup {
              settings = lsp_settings.lua_ls or {},
            }
          end,

          rust_analyzer = function()
            require('rust-tools').setup {
              tools = {
                inlay_hints = {
                  auto = false,
                  parameter_hints_prefix = c.use_icons and '  ' or ' <- ',
                  other_hints_prefix = c.use_icons and ' • ' or ' >> ',
                  highlight = 'NonText',
                },
                hover_actions = {
                  border = c.border,
                },
              },
              server = {
                standalone = true,
                cmd = when(env.is_win32, { 'cmd', '/c', 'rust-analyzer' }),
                settings = lsp_settings.rust_analyzer or {},
              },
            }
          end,

          tsserver = function()
            local ts_utils = require 'nvim-lsp-ts-utils'
            lspconfig.tsserver.setup {
              autostart = lspconfig.util.default_config.autostart
                and require('rc.lib.typescript_detector').opened_node_project(),
              init_options = ts_utils.init_options,
              settings = lsp_settings.tsserver or {},
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
              settings = lsp_settings.denols or {},
              autostart = lspconfig.util.default_config.autostart
                and not require('rc.lib.typescript_detector').opened_node_project(),
            }
          end,

          clangd = function()
            local capabilities = deepcopy(default_config.capabilities)
            capabilities.offsetEncoding = 'utf-8'
            lspconfig.clangd.setup {
              handlers = (function()
                local lsp_status
                ok, lsp_status = pcall(require, 'lsp-status')
                if not ok then
                  return nil
                end
                return lsp_status.extensions.clangd.setup()
              end)(),
              single_file_support = true,
              capabilities = capabilities,
              settings = lsp_settings.clangd or {},
            }
          end,

          html = function()
            lspconfig.html.setup {
              filetypes = { 'html', 'htmldjango' },
            }
          end,

          emmet_ls = function()
            lspconfig.emmet_ls.setup {
              filetypes = {
                'html',
                'htmldjango',
                'javascriptreact',
                'typescriptreact',
              },
            }
          end,
        }
      end

      configure_servers()

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
            settings = lsp_settings.jdtls or {},

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
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'mason.nvim' },
    lazy = true,
    config = true,
  },
  {
    'folke/neodev.nvim',
    lazy = true,
    config = function()
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

      require('neodev').setup { runtime_path = true }
    end,
  },
  {
    'williamboman/mason.nvim',
    lazy = true,
    opts = {
      ui = {
        border = c.border,
        icons = {
          package_installed = c.use_icons and '' or '*',
          package_uninstalled = c.use_icons and '' or '-',
          package_pending = c.use_icons and '' or '+',
        },
      },
    },
  },
  {
    'simrat39/rust-tools.nvim',
    lazy = true,
  },
  {
    'jose-elias-alvarez/nvim-lsp-ts-utils',
    lazy = true,
  },
  {
    'mfussenegger/nvim-jdtls',
    lazy = true,
  },
  {
    'folke/neoconf.nvim',
    cmd = 'Neoconf',
    config = true,
  },
}
