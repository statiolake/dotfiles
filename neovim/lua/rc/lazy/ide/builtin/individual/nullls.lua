local ac = require 'rc.lib.autocmd'

local source_configs = {
  pylint = {
    base = 'diagnostics.pylint',
    extra_args = {
      string.format(
        '--disable=%s',
        table.concat({
          'missing-module-docstring',
          'missing-class-docstring',
          'missing-function-docstring',
        }, ',')
      ),
    },
  },
  clang_format = {
    base = 'formatting.clang_format',
    filetypes = { 'c', 'cpp', 'java', 'cuda' },
    extra_args = {
      table.concat {
        '-style={',
        '  BasedOnStyle: LLVM,',
        '  AlignAfterOpenBracket: true,',
        '  AlignEscapedNewlines: Left,',
        '  AlignOperands: true,',
        '  AllowShortBlocksOnASingleLine: false,',
        '  AllowShortCaseLabelsOnASingleLine: true,',
        '  AllowShortFunctionsOnASingleLine: false,',
        '  AllowShortIfStatementsOnASingleLine: true,',
        '  AllowShortLoopsOnASingleLine: true,',
        '  AlwaysBreakTemplateDeclarations: true,',
        '  BreakBeforeBraces: Attach,',
        '  BreakBeforeTernaryOperators: true,',
        '  BreakConstructorInitializers: BeforeComma,',
        '  BreakStringLiterals: true,',
        '  ColumnLimit: 78,',
        '  CompactNamespaces: true,',
        '  IncludeBlocks: Preserve,',
        '  IndentCaseLabels: true,',
        '  IndentWidth: 4,',
        '  NamespaceIndentation: Inner,',
        '  ReflowComments: true,',
        '  SortIncludes: true,',
        '  SortUsingDeclarations: true,',
        '  SpaceBeforeAssignmentOperators: true,',
        '  SpaceBeforeParens: ControlStatements,',
        '}',
      },
    },
  },
  prettier = {
    base = 'formatting.prettier',
    filetypes = {
      'javascript',
      'javascriptreact',
      'typescriptreact',
      'vue',
      'css',
      'scss',
      'less',
      'html',
      'json',
      'jsonc',
      'yaml',
      'markdown',
      'graphql',
      'handlebars',
    },
  },
  prettier_typescript = {
    base = 'formatting.prettier',
    filetypes = { 'typescript' },
    condition = function(params)
      local _ = params
      -- deno でないなら prettier を有効化する
      return require('rc.lib.typescript_detector').opened_node_project()
    end,
  },
  -- eslint = {
  --   base = 'diagnostics.eslint',
  --   prefer_local = 'node_modules/.bin', --プロジェクトローカルがある場合はそれを利用
  -- },
  djlint_formatting = {
    base = 'formatting.djlint',
    extra_args = function(params)
      local vimfn = require 'rc.lib.vimfn'
      local djlintrc =
        vimfn.expand(string.format('%s/.djlintrc', params.root))
      if vim.fn.filereadable(djlintrc) == 0 then
        return {
          '--blank-line-after-tag',
          'load,extends,include,endblock',
          '--blank-line-before-tag',
          'load,extends,include,block',
          '--indent',
          vim.opt_local.shiftwidth:get(),
          '--max-line-length',
          vim.opt_local.textwidth:get(),
          '--preserve-blank-lines',
        }
      else
        return {}
      end
    end,
  },
  djlint_diagnostics = {
    base = 'diagnostics.djlint',
  },
  rustfmt = {
    base = 'formatting.rustfmt',
  },
  goimports = {
    base = 'formatting.goimports',
  },
  isort = {
    base = 'formatting.isort',
    command = 'python',
    args = function(params)
      local _ = params
      return {
        '-m',
        'isort',
        '--stdout',
        '--filename',
        '$FILENAME',
        '-',
        '--profile=black',
        string.format('--line-length=%d', vim.opt_local.textwidth:get()),
      }
    end,
  },
  black = {
    base = 'formatting.black',
    command = 'python',
    args = function(params)
      local _ = params
      return {
        '-m',
        'black',
        '--stdin-filename',
        '$FILENAME',
        '-',
        string.format('--line-length=%d', vim.opt_local.textwidth:get()),
      }
    end,
  },
  stylua = {
    base = 'formatting.stylua',
  },
}

return {
  {
    'jose-elias-alvarez/null-ls.nvim',
    denendencies = { 'mason.nvim' },
    lazy = true,
    config = function()
      local null_ls = require 'null-ls'

      local function configure_sources()
        local sources = {}
        for _, config in pairs(source_configs) do
          local kind, name = unpack(vim.split(config.base, '%.'))
          local base_source = null_ls.builtins[kind][name]
          config.base = nil
          table.insert(sources, base_source.with(config))
        end

        null_ls.setup {
          debug = true,
          sources = sources,
        }
      end

      configure_sources()
    end,
  },
  {
    'jayp0521/mason-null-ls.nvim',
    dependencies = { 'mason.nvim' },
    lazy = true,
  },
}
