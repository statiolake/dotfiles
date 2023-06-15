local ac = require 'rc.lib.autocmd'

local cg = get_global_config

return {
  {
    'jose-elias-alvarez/null-ls.nvim',
    config = function()
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

      local ok, _ = require 'config-local'
      if ok then
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
  },
  {
    'jayp0521/mason-null-ls.nvim',
    dependencies = { 'mason.nvim', 'null-ls.nvim' },
    config = function() end,
  },
}
