local ls = require 'luasnip'

local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local l = require('luasnip.extras').lambda
local rep = require('luasnip.extras').rep
local p = require('luasnip.extras').partial
local m = require('luasnip.extras').match
local n = require('luasnip.extras').nonempty
local dl = require('luasnip.extras').dynamic_lambda
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta
local types = require 'luasnip.util.types'
local conds = require 'luasnip.extras.expand_conditions'

local function parse_lsp(context, snippet)
  if type(snippet) == 'table' then
    snippet = table.concat(snippet, '\n')
  end
  return ls.parser.parse_snippet(context, snippet)
end

local function copy(args)
  return args[1]
end

ls.cleanup()

ls.snippets.latex = {
  parse_lsp('docclass', {
    '\\\\documentclass[dvipdfmx, a4j]{ujarticle}',
    '\\\\西暦',
    '\\\\usepackage{plext}',
    '\\\\usepackage{color}',
    '\\\\usepackage{graphicx}',
    '\\\\usepackage{amsmath, amssymb, amsthm}',
    '\\\\usepackage{cancel}',
    '\\\\usepackage{ulem}',
    '\\\\usepackage{framed}',
    '\\\\usepackage{cases}',
    '\\\\usepackage{setspace}',
    '\\\\usepackage{ifthen}',
    '\\\\usepackage[shortlabels,inline]{enumitem}',
    '\\\\usepackage{hhline}',
    '\\\\usepackage{myzmath}',
    '\\\\usepackage{myxphysics}',
    '\\\\usepackage{myunit}',
    '\\\\usepackage[top=15truemm,bottom=15truemm,left=15truemm,right=15truemm]{geometry}',
    '% \\\\usepackage{helvet}',
    '\\\\usepackage{titlesec}',
    '\\\\titleformat*{\\\\section}{\\\\fontsize{16}{25}\\\\bfseries\\\\sffamily}',
    '\\\\titleformat*{\\\\subsection}{\\\\fontsize{14}{25}\\\\bfseries\\\\sffamily}',
    '\\\\titleformat*{\\\\subsubsection}{\\\\fontsize{12}{25}\\\\bfseries\\\\sffamily}',
    '\\\\titleformat*{\\\\paragraph}{\\\\normalsize\\\\bfseries\\\\sffamily}',
    '\\\\titleformat*{\\\\subparagraph}{\\\\normalsize\\\\bfseries\\\\sffamily}',
    '\\\\renewcommand{\\\\textbf}[1]{{\\\\bfseries\\\\sffamily #1}}',
    '\\\\theoremstyle{definition}',
    '\\\\newtheorem{theorem}{定理}',
    '\\\\newtheorem{definition}[theorem]{定義}',
    '\\\\newtheorem{lemma}[theorem]{補題}',
    '\\\\newtheorem{corollary}[theorem]{系}',
    '\\\\newtheorem*{theorem*}{定理}',
    '\\\\newtheorem*{definition*}{定義}',
    '\\\\newtheorem*{lemma*}{補題}',
    '\\\\newtheorem*{corollary*}{系}',
    '\\\\begin{document}',
    '$0',
    '\\\\end{document}',
    '',
  }),
  parse_lsp('package_tikz', {
    '\\\\usepackage{pgf,tikz,pgfplots,tikz-cd}',
    '\\\\usepackage{gnuplot-lua-tikz}',
    '\\\\usetikzlibrary{decorations.markings}',
    '\\\\pgfplotsset{compat=1.16}',
  }),
  parse_lsp('deftitle', {
    '\\\\title{$1}',
    '\\\\author{${2:理学研究科 数学教室 中井大介 \\\\\\\\ 0530--33--7718}}',
    '\\\\date{${3:\\\\today}}',
  }),
  parse_lsp('counterwithsection', {
    '\\\\makeatletter',
    '\\\\renewcommand{\\\\thefigure}{\\\\thesection.\\\\arabic{figure}}',
    '\\\\@addtoreset{figure}{section}',
    '\\\\renewcommand{\\\\thetable}{\\\\thesection.\\\\arabic{table}}',
    '\\\\@addtoreset{table}{section}',
    '\\\\renewcommand{\\\\theequation}{\\\\thesection.\\\\arabic{equation}}',
    '\\\\@addtoreset{equation}{section}',
    '\\\\makeatother',
  }),
  parse_lsp('env', { '\\\\begin{${1:align*}}', '\t$0', '\\\\end{$1}' }),
  parse_lsp(
    'envd',
    { '\\\\begin{${1:tabular}}{${2:cc}}', '\t$0', '\\\\end{$1}' }
  ),
  parse_lsp(
    'envop',
    { '\\\\begin{${1:enumerate}}[${2:(1)}]', '\t$0', '\\\\end{$1}' }
  ),
  parse_lsp('minipage', {
    '\\\\begin{minipage}{${1:.3\\\\\\\\hsize}}',
    '',
    '\\\\end{minipage}',
    '\\\\hfill',
    '\\\\begin{minipage}{${2:.6\\\\\\\\hsize}}',
    '',
    '\\\\end{minipage} \\\\\\\\',
    '$0',
  }),
  parse_lsp('li', '\\\\item $0'),
  parse_lsp('part', '\\\\part{${1:partname}}\\\\label{prt:${2:label}}'),
  parse_lsp('cha', '\\\\chapter{${1:chaptername}}\\\\label{prt:${2:label}}'),
  parse_lsp('sec', '\\\\section{${1:sectionname}}\\\\label{prt:${2:label}}'),
  parse_lsp(
    'ssec',
    '\\\\subsection{${1:subsectionname}}\\\\label{prt:${2:label}}'
  ),
}

ls.snippets.tex = ls.snippets.latex

ls.snippets.python = {
  parse_lsp('ifmain', {
    'if __name__ == "__main__":',
    '\tmain()',
  }),
}

ls.snippets.rust = {
  parse_lsp('impldisplay', {
    'impl fmt::Display for $1 {',
    '\tfn fmt(&self, b: &mut fmt::Formatter) -> fmt::Result {',
    '\t\twrite!(b, $0)',
    '\t}',
    '}',
  }),
  parse_lsp(
    'derives',
    '#[derive(Debug${1:, Clone}${2:, Copy}${3:, PartialEq, Eq, Hash}${4:, PartialOrd, Ord})]'
  ),
  parse_lsp('box', 'Box::new(${0:$TM_SELECTED_TEXT})'),
  parse_lsp('ok', 'Ok(${0:$TM_SELECTED_TEXT})'),
  parse_lsp('some', 'Some(${0:$TM_SELECTED_TEXT})'),
}
