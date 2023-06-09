local use = require('rc.lib.plugin_manager').use
local cg = get_global_config

local treesitter_enabled = cg 'editor.useTreesitter'

use {
  'iamcco/markdown-preview.nvim',
  enabled = cg 'editor.ide.framework' ~= 'coc',
  on_ft = { 'markdown' },
  after_load = function()
    vim.fn['mkdp#util#install']()
  end,
}

-- use {
--   'lervag/vimtex',
--   enabled = cg 'editor.ide.framework' ~= 'coc',
--   on_ft = { 'tex', 'plaintex' },
--   before_load = function()
--     -- tex ファイルを開いたときデフォルトで ft=tex と考える
--     -- (plaintex で開かれたりして厄介なため)
--     vim.g.tex_flavor = 'latex'
--     vim.g.vimtex_compiler_latexmk = { continuous = 0 }
--
--     vim.g.vimtex_view_method = 'general'
--     if env.is_win32 then
--       vim.g.vimtex_view_general_viewer =
--         vim.fn.expand '~/AppData/Local/SumatraPDF/SumatraPDF.exe'
--       vim.g.vimtex_view_general_options =
--         '-reuse-instance -forward-search @tex @line @pdf'
--     else
--       if b(vim.fn.executable 'zathura') then
--         vim.g.vimtex_view_general_viewer = 'zathura'
--         vim.g.vimtex_view_general_options = table.concat({
--           '-x',
--           string.format(
--             [["nvim --server '%s' --remote '%%{input}:%%{line}'"]],
--             vim.v.servername
--           ),
--           '--synctex-forward',
--           '@line:0:@tex',
--           '@pdf',
--         }, ' ')
--       else
--         vim.g.vimtex_view_general_options = 'xdg-open'
--         vim.g.vimtex_view_general_viewer = '@pdf'
--       end
--     end
--   end,
-- }

use {
  'rust-lang/rust.vim',
  before_load = function()
    vim.g.rustfmt_fail_silently = 1
  end,
}

-- 追加のファイルタイプ
use {
  'Snape3058/kotlin-vim',
  enabled = not treesitter_enabled,
}

use {
  'PProvost/vim-ps1',
  enabled = not treesitter_enabled,
}

use {
  'vim-python/python-syntax',
  enabled = not treesitter_enabled,
  before_load = function()
    vim.g.python_highlight_all = 1
    vim.g.python_version_2 = 0
  end,
}

use {
  'cespare/vim-toml',
  enabled = not treesitter_enabled,
  rev = 'main',
}

use {
  'rhysd/vim-crystal',
  enabled = not treesitter_enabled,
  before_load = function()
    vim.g.crystal_define_mappings = 0
  end,
}

use {
  'tkztmk/vim-vala',
  enabled = not treesitter_enabled,
}

use {
  'zah/nim.vim',
  enabled = not treesitter_enabled,
}

use {
  'JuliaEditorSupport/julia-vim',
  enabled = not treesitter_enabled,
}

-- use {
--   'jlcrochet/vim-cs',
--   enabled = not treesitter_enabled,
-- }

-- use {
--   'jlcrochet/vim-razor',
--    enabled = not treesitter_enabled,
-- }

use {
  'leafgarland/typescript-vim',
  enabled = not treesitter_enabled,
}

use {
  'bfrg/vim-cpp-modern',
  enabled = not treesitter_enabled,
  before_load = function()
    vim.g.cpp_class_scope_highlight = 1
    vim.g.cpp_member_variable_highlight = 1
    vim.g.cpp_decl_highlight = 1
    vim.g.cpp_experimental_simple_tepmlate_highlight = 1
    vim.g.cpp_experimental_template_highlight = 1
    vim.g.cpp_concepts_highlight = 1
  end,
}

use {
  'kevinoid/vim-jsonc',
  enabled = not treesitter_enabled,
}
