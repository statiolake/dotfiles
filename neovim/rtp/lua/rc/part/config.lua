local use_icons = false

set_global_config {
  ['editor.simpleMode'] = vim.g.simple_mode,
  ['editor.formatOnSave'] = true,
  ['editor.ide.framework'] = 'builtin', -- [builtin, coc]
  ['editor.ide.coc.selector'] = 'coc', -- [telescope, coc, fzf]
  ['editor.ide.builtin.completion'] = 'nvim-cmp', -- [ddc, nvim-cmp]
  ['editor.ide.builtin.useFloatPum'] = true,
  ['editor.ide.builtin.useSnip'] = 'triggerOnly', -- [always, triggerOnly, never], only with ddc
  ['editor.ide.builtin.selector'] = 'telescope', -- [telescope, fzf, ddu]
  ['editor.ide.builtin.snippet'] = 'ultisnips', -- [vsnip, ultisnips], only with cmp
  ['editor.useTreesitter'] = true,
  ['editor.ime'] = 'native',
  ['ui.useIcons'] = use_icons,
  ['ui.colorset'] = 'alduin',
  ['ui.transparent'] = false,
  ['ui.font.size'] = 11,
  ['ui.font.linespace'] = 4,
  ['ui.font.en.win32'] = 'Consolas',
  ['ui.font.jp.win32'] = 'Meiryo',
  ['ui.font.en.linux'] = 'Hack NF',
  ['ui.font.jp.linux'] = 'M+ 1m',
  ['ui.font.enjp.win32'] = nil, --'cosmei',
  ['ui.font.enjp.linux'] = nil,
  ['ui.signs.diagnostics.error'] = use_icons and '' or '#',
  ['ui.signs.diagnostics.warning'] = use_icons and '' or '!',
  ['ui.signs.diagnostics.info'] = use_icons and '' or '=',
  ['ui.signs.diagnostics.hint'] = use_icons and '' or '>',
  ['ui.signs.diff.added'] = use_icons and '┃' or '+',
  ['ui.signs.diff.change_removed'] = use_icons and '┃' or '~',
  ['ui.signs.diff.changed'] = use_icons and '┃' or '~',
  ['ui.signs.diff.removed'] = use_icons and '' or '_',
  ['ui.signs.diff.top_removed'] = use_icons and '' or '‾',
  -- ['ui.border'] = {
  --   { '╭', 'FloatBorder' },
  --   { '─', 'FloatBorder' },
  --   { '╮', 'FloatBorder' },
  --   { '│', 'FloatBorder' },
  --   { '╯', 'FloatBorder' },
  --   { '─', 'FloatBorder' },
  --   { '╰', 'FloatBorder' },
  --   { '│', 'FloatBorder' },
  -- },
  -- ['ui.border'] = {
  --   { '┌', 'FloatBorder' },
  --   { '─', 'FloatBorder' },
  --   { '┐', 'FloatBorder' },
  --   { '│', 'FloatBorder' },
  --   { '┘', 'FloatBorder' },
  --   { '─', 'FloatBorder' },
  --   { '└', 'FloatBorder' },
  --   { '│', 'FloatBorder' },
  -- },
  -- ['ui.border'] = {
  --   { '+', 'FloatBorder' },
  --   { '-', 'FloatBorder' },
  --   { '+', 'FloatBorder' },
  --   { '|', 'FloatBorder' },
  --   { '+', 'FloatBorder' },
  --   { '-', 'FloatBorder' },
  --   { '+', 'FloatBorder' },
  --   { '|', 'FloatBorder' },
  -- },
  ['ui.border'] = {
    { ' ', 'FloatBorder' },
    { ' ', 'FloatBorder' },
    { ' ', 'FloatBorder' },
    { ' ', 'FloatBorder' },
    { ' ', 'FloatBorder' },
    { ' ', 'FloatBorder' },
    { ' ', 'FloatBorder' },
    { ' ', 'FloatBorder' },
  },
  ['ui.preferredSplit'] = function()
    if vim.fn.winwidth(0) < vim.fn.winheight(0) * 3 then
      -- 縦長
      return 'split'
    else
      -- 横長
      return 'vsplit'
    end
  end,
  ['lsp.pyright.python.analysis.diagnosticMode'] = 'workspace',
  ['lsp.pyright.python.analysis.typeCheckingMode'] = 'basic',
  ['lsp.rust_analyzer.rust-analyzer.assist.importEnforceGranularity'] = true,
  ['lsp.rust_analyzer.rust-analyzer.assist.importGranularity'] = 'crate',
  ['lsp.rust_analyzer.rust-analyzer.callInfo.full'] = true,
  ['lsp.rust_analyzer.rust-analyzer.checkOnSave.command'] = 'clippy',
  ['lsp.rust_analyzer.rust-analyzer.procMacro.enable'] = true,
  ['lsp.rust_analyzer.rust-analyzer.rustfmt.overrideCommand'] = {
    'cargo',
    'clippy',
    '--workspace',
    '--message-format=json',
    '--all-targets',
  },
  ['lsp.lua_ls.Lua.IntelliSense.traceBeSetted'] = true,
  ['lsp.lua_ls.Lua.IntelliSense.traceFieldInject'] = true,
  ['lsp.lua_ls.Lua.IntelliSense.traceLocalSet'] = true,
  ['lsp.lua_ls.Lua.IntelliSense.traceReturn'] = true,
  ['lsp.lua_ls.Lua.completion.callSnippet'] = 'Both',
  ['lsp.gopls.gopls.staticcheck'] = true,
  ['lsp.gopls.gopls.analyses.ST1000'] = false,
  ['lsp.gopls.gopls.analyses.ST1003'] = true,
  ['lsp.gopls.gopls.analyses.ST1016'] = false,
  ['lsp.gopls.gopls.analyses.ST1020'] = false,
  ['lsp.gopls.gopls.analyses.ST1021'] = false,
  ['lsp.gopls.gopls.analyses.ST1022'] = true,
  ['lsp.gopls.gopls.analyses.ST1023'] = true,
  ['nullLs.sources.pylint.base'] = 'diagnostics.pylint',
  ['nullLs.sources.pylint.extraArgs'] = {
    string.format(
      '--disable=%s',
      table.concat({
        'missing-module-docstring',
        'missing-class-docstring',
        'missing-function-docstring',
      }, ',')
    ),
  },
  ['nullLs.sources.clang_format.base'] = 'formatting.clang_format',
  ['nullLs.sources.clang_format.filetypes'] = { 'c', 'cpp', 'java', 'cuda' },
  ['nullLs.sources.clang_format.extraArgs'] = {
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
  ['nullLs.sources.prettier.base'] = 'formatting.prettier',
  ['nullLs.sources.prettier.filetypes'] = {
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
  ['nullLs.sources.prettier_typescript.base'] = 'formatting.prettier',
  ['nullLs.sources.prettier_typescript.filetypes'] = { 'typescript' },
  ['nullLs.sources.prettier_typescript.condition'] = function(params)
    local _ = params
    -- deno でないなら prettier を有効化する
    return require('rc.lib.typescript_detector').opened_node_project()
  end,
  ['nullLs.sources.djlint_formatting.base'] = 'formatting.djlint',
  ['nullLs.sources.djlint_formatting.extraArgs'] = function(params)
    local vimfn = require 'rc.lib.vimfn'
    local djlintrc = vimfn.expand(string.format('%s/.djlintrc', params.root))
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
  ['nullLs.sources.djlint_diagnostics.base'] = 'diagnostics.djlint',
  ['nullLs.sources.rustfmt.base'] = 'formatting.rustfmt',
  ['nullLs.sources.goimports.base'] = 'formatting.goimports',
  ['nullLs.sources.isort.base'] = 'formatting.isort',
  ['nullLs.sources.isort.command'] = 'python',
  ['nullLs.sources.isort.args'] = function(params)
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
  ['nullLs.sources.black.base'] = 'formatting.black',
  ['nullLs.sources.black.command'] = 'python',
  ['nullLs.sources.black.args'] = function(params)
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
  ['nullLs.sources.stylua.base'] = 'formatting.stylua',
}

if b(vim.fn.executable 'zathura') then
  set_global_config {
    ['lsp.texlab.texlab.forwardSearch.executable'] = 'zathura',
    ['lsp.texlab.texlab.forwardSearch.args'] = {
      '-x',
      string.format(
        [[nvim --server '%s' --remote '%%{input}:%%{line}']],
        vim.v.servername
      ),
      '--synctex-forward',
      '%l:0:%f',
      '%p',
    },
  }
end
