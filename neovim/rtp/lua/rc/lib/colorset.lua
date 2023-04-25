local ac = require 'rc.lib.autocmd'
local cmd = require 'rc.lib.command'
local msg = require 'rc.lib.msg'

local colorsets = {}
local active_colorset = nil

---Set editor colorscheme
local function set_colorscheme(scheme)
  vim.cmd(string.format('colorscheme %s', scheme))
  ac.emit('ColorScheme', scheme)
end

---Register default additional highlights
local function register_default_additional_highlights()
  vim.cmd [[hi default link FloatBorder NormalFloat]]
  vim.cmd [[hi default link SubCursor Cursor]]
  vim.cmd [[hi Underlined guisp=fg]]
end

---Register default LSP highlights
local function register_default_lsp_highlights()
  -- DefaultErrorLine - ソースコード中のエラー行の強調。通常は薄赤背景。
  -- DefaultError - ソースコード中のエラー部分のハイライト。通常は波線。
  -- DefaultErrorText - エラーメッセージ等を表示するハイライト。通常は赤色。
  -- (Warn, Info, Hint も同様)
  vim.cmd [[
    hi default      DefaultErrorLine guibg=NONE guifg=NONE
    hi default      DefaultWarnLine  guibg=NONE guifg=NONE
    hi default      DefaultInfoLine  guibg=NONE guifg=NONE
    hi default      DefaultHintLine  guibg=NONE guifg=NONE
    hi default link DefaultError SpellBad
    hi default link DefaultWarn  SpellCap
    hi default      DefaultInfo  guibg=NONE guifg=NONE
    hi default      DefaultHint  guibg=NONE guifg=NONE
    hi default link DefaultErrorText Error
    hi default      DefaultWarnText guibg=NONE guifg=NONE
    hi default      DefaultInfoText guibg=NONE guifg=NONE
    hi default      DefaultHintText guibg=NONE guifg=NONE
    hi default link DefaultErrorTextOnErrorLine DefaultErrorText
    hi default link DefaultWarnTextOnWarnLine DefaultWarnText
    hi default link DefaultInfoTextOnInfoLine DefaultInfoText
    hi default link DefaultHintTextOnHintLine DefaultHintText
    hi default link DefaultReference Search

    " coc
    hi! link CocErrorSign DefaultErrorText
    hi! link CocErrorVirtualText DefaultErrorText
    hi! link CocErrorHighlight DefaultError
    hi! link CocWarningSign DefaultWarnText
    hi! link CocWarningVirtualText DefaultWarnText
    hi! link CocWarningHighlight DefaultWarn
    hi! link CocHintSign DefaultHintText
    hi! link CocHintVirtualText DefaultHintText
    hi! link CocHintHighlight DefaultHint
    hi! link CocInfoSign DefaultInfoText
    hi! link CocInfoVirtualText DefaultInfoText
    hi! link CocInfoHighlight DefaultInfo
    hi! link CocHighlightText DefaultReference
    hi! link CocRustChainingHint NonText
    hi! link CocRustTypeHint NonText
    hi! link CocCodeLens NonText

    " Built-in LSP
    hi! link DiagnosticError DefaultErrorText
    hi! link DiagnosticSignError DefaultErrorText
    hi! link DiagnosticUnderlineError DefaultError
    hi! link DiagnosticWarn DefaultWarnText
    hi! link DiagnosticSignWarn DefaultWarnText
    hi! link DiagnosticUnderlineWarn DefaultWarn
    hi! link DiagnosticHint DefaultHintText
    hi! link DiagnosticSignHint DefaultHintText
    hi! link DiagnosticUnderlineHint DefaultHint
    hi! link DiagnosticInfo DefaultInfoText
    hi! link DiagnosticSignInfo DefaultInfoText
    hi! link DiagnosticUnderlineInfo DefaultInfo
    hi! link ReferenceText DefaultReference
    hi! link ReferenceRead LspReferenceText
    hi! link ReferenceWrite LspReferenceText
  ]]
end

local function register_default_semantic_tokens_highlights()
  vim.cmd [[
    hi link Namespace Include
    hi link Class Type
    hi link Enum Class
    hi link Interface Class
    hi link Struct Class
    hi link TypeParameter Class
    "hi link Type Type
    hi link Parameter Variable
    hi link Variable Identifier
    hi link Property Variable
    hi link EnumMember Constant
    hi link Event Variable
    "hi link Function Function
    hi link Method Function
    "hi link Macro Constant
    hi link Label Constant
    "hi link Comment Comment
    "hi link String String
    "hi link Keyword Keyword
    "hi link Number Number
    hi link Regexp Constant
    "hi link Operator
  ]]
end

local function register_default_treesitter_highlights()
  -- デフォルトのカラー
  vim.cmd [[
    hi! link @annotation PreProc
    hi! link @attribute PreProc

    hi! link @boolean Boolean
    hi! link @character Character
    hi! link @float Float

    hi! link @conditional Conditional

    hi! link @constant Constant
    hi! link @const.builtin Define
    hi! link @const.macro Macro

    hi! link @constructor Structure

    hi! link @error Structure
    hi! link @exception Structure

    hi! link @field Variable

    hi! link @function Function
    hi! link @function.builtin Function
    hi! link @function.macro Macro

    hi! link @include PreProc

    hi! link @keyword Keyword
    hi! link @keyword.function Keyword
    hi! link @keyword.operator Operator

    hi! link @label Label

    hi! link @method Function

    hi! link @namespace Namespace

    hi! link @none Constant
    hi! link @number Number

    hi! link @operator Operator

    hi! link @parameter Parameter
    hi! link @parameter.reference Parameter

    hi! link @property Variable

    hi! link @punctuation Operator
    hi! link @punctuation.delimiter Operator
    hi! link @punctuation.bracket Operator
    hi! link @punctuation.special Operator

    hi! link @repeat Repeat

    hi! link @string String
    hi! link @string.regex String
    hi! link @string.escape String

    hi! link @tag Tag
    hi! link @tag.delimiter Operator

    hi! link @text String
    hi! link @strong Underlined
    hi! link @emphasis Underlined
    hi! link @underline Underlined
    hi! link @title Underlined
    hi! link @literal Constant
    hi! link @uri String

    hi! link @type Type
    hi! link @type.builtin Type
    hi! link @variable Variable
    hi! link @variable.builtin Special
  ]]
end

local hooks = {}

local function register_editor_colorscheme_hook(hook)
  table.insert(hooks, hook)
end

local function run_editor_colorscheme_hooks()
  for _, hook in ipairs(hooks) do
    hook()
  end
end

register_editor_colorscheme_hook(register_default_additional_highlights)
register_editor_colorscheme_hook(register_default_lsp_highlights)
register_editor_colorscheme_hook(register_default_semantic_tokens_highlights)
register_editor_colorscheme_hook(register_default_treesitter_highlights)

local M = {}

---List registered colorsets
function M.list_colorsets()
  local names = table.iter_keys(colorsets, pairs):to_table()
  print(table.concat(names, ' '))
end

---Setup colorset library
function M.setup(colorset)
  -- 起動したままカラーセットを切り替えるために :Colorset コマンドを追加する
  cmd.add('Colorset', function(ctx)
    if #ctx.args > 0 then
      M.apply(ctx.args[1])
    else
      M.list_colorsets()
    end
  end, {
    nargs = '?',
    complete = require('rc.lib.completer_helper').create_completer_from_static_list(
      table.iter_keys(colorsets, pairs):to_table()
    ),
  })

  -- 起動時に初期カラーセットを登録する
  if colorset then
    ac.on_uienter(function()
      M.apply(colorset)
    end)
  end
end

---Register new colorset
---@param name string name of colorset
---@param colorset table colorset specification with following entries:
---  - background: 'light' or 'black'
---  - editor: colorscheme for editor
---  - hook: function executed after this colorset is applied
function M.register(name, colorset)
  if colorsets[name] ~= nil then
    msg.warn('colorset "%s" is already registered; override', name)
  end
  colorsets[name] = colorset
end

M.register_editor_colorscheme_hook = register_editor_colorscheme_hook

---Get all colorset specifications
function M.get_all()
  return deepcopy(colorsets)
end

---Get specific (or active if name is nil) colorset specifications
function M.get(name)
  return name and deepcopy(colorsets[name]) or deepcopy(active_colorset)
end

---Apply specified colorset
function M.apply(name)
  active_colorset = colorsets[name]
  if active_colorset == nil then
    msg.error('unknown colorset: %s', name)
    return
  end

  local background = active_colorset.background
  if background then
    vim.opt.background = background
  end

  local editor = active_colorset.editor
  if editor then
    set_colorscheme(editor)
    run_editor_colorscheme_hooks()
  end

  local hook = active_colorset.hook
  if hook then
    hook()
  end
end

return M
