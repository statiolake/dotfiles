local env = require 'rc.lib.env'
local ac = require 'rc.lib.autocmd'
local k = require 'rc.lib.keybind'
local vimfn = require 'rc.lib.vimfn'
local c = require 'rc.config'

return {
  {
    'hrsh7th/nvim-cmp',
    dependencies = pack {
      'cmp-nvim-lsp',
      'cmp-buffer',
      'cmp-path',
      'cmp-cmdline',
      'lspkind.nvim',
      'ultisnips',
      'cmp-nvim-ultisnips',
    },
    event = 'InsertEnter',
    config = function()
      local snip = require 'rc.lib.ultisnips_wrapper'
      local cmp = require 'cmp'

      local function check_back_space()
        local col = vim.fn.col '.' - 1
        if col == 0 or string.sub(vimfn.getline '.', col, col):match '%s' then
          return true
        else
          return false
        end
      end

      local function on_tab(fallback)
        if cmp.visible() then
          -- 展開前に undo ポイントを作っておく
          vim.api.nvim_feedkeys(k.t '<C-g>u', 'int', false)
          cmp.confirm {
            behavior = cmp.ConfirmBehavior.Insert,
            select = true,
          }
        else
          if b(snip.jumpable(1)) then
            snip.jump_next()
          elseif check_back_space() then
            fallback()
          else
            cmp.complete()
          end
        end
      end

      local on_s_tab = function(fallback)
        if b(snip.jumpable(-1)) then
          snip.jump_prev()
        else
          fallback()
        end
      end

      local on_cr = function(fallback)
        if cmp.get_selected_entry() then
          cmp.confirm {
            behavior = cmp.ConfirmBehavior.Insert,
            select = false,
          }
        else
          cmp.abort()

          local keyseq = k.t '<CR>'

          -- この改行地点より後ろに文字がある場合は整形する
          local back_str = string.sub(vimfn.getline '.', vim.fn.col '.')
          local trimmed_back_str = string.gsub(back_str, '^%s*(.-)%s*$', '%1')
          if trimmed_back_str ~= '' then
            -- 基本は空白行を入れない
            keyseq = k.t '<CR><Esc>==I'
            for _, endpair in ipairs { ')', ']', '}', '>' } do
              if string.starts_with(trimmed_back_str, endpair) then
                -- 終わりなら空白行を入れる
                keyseq = k.t '<CR><Esc>==O'
                break
              end
            end
          end

          vim.api.nvim_feedkeys(keyseq, 'nt', false)
        end
      end

      local types = require 'cmp.types'
      cmp.setup {
        completion = {
          completeopt = 'menu,menuone,noselect',
        },
        -- confirmation = {
        --   get_commit_characters = function(chars)
        --     -- (特に OmniSharp で) 誤爆が多すぎるので " " を除く。
        --     -- return vim.tbl_filter(function(char) return char ~= " " end, chars)
        --
        --     -- それでも誤爆が多いので完全に無にする
        --     return {}
        --   end,
        -- },
        snippet = {
          expand = function(args)
            snip.anonymous(args.body)
          end,
        },
        mapping = {
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.close(),
          ['<Tab>'] = cmp.mapping(on_tab),
          ['<S-Tab>'] = cmp.mapping(on_s_tab),
          ['<CR>'] = cmp.mapping(on_cr),
          ['<Down>'] = cmp.mapping.select_next_item {
            behavior = types.cmp.SelectBehavior.Insert,
          },
          ['<Up>'] = cmp.mapping.select_prev_item {
            behavior = types.cmp.SelectBehavior.Insert,
          },
          ['<A-j>'] = cmp.mapping.select_next_item {
            behavior = types.cmp.SelectBehavior.Insert,
          },
          ['<A-k>'] = cmp.mapping.select_prev_item {
            behavior = types.cmp.SelectBehavior.Insert,
          },
          ['<C-n>'] = cmp.mapping.select_next_item {
            behavior = types.cmp.SelectBehavior.Insert,
          },
          ['<C-p>'] = cmp.mapping.select_prev_item {
            behavior = types.cmp.SelectBehavior.Insert,
          },
        },
        sources = {
          { name = 'ultisnips' },
          { name = 'nvim_lsp' },
          {
            name = 'buffer',
            option = {
              get_bufnrs = function()
                return vim.api.nvim_list_bufs()
              end,
            },
          },
        },
        view = {
          entries = 'custom',
        },
        experimental = {
          --ghost_text = { hl_group = 'NonText' },
          ghost_text = false,
        },
        formatting = {
          fields = { 'kind', 'abbr', 'menu' },
          format = function(entry, vim_item)
            local f = require('lspkind').cmp_format {
              mode = c.use_icons and 'symbol' or 'text',
              maxwidth = 50,
            }(entry, vim_item)

            f.kind = string.format(
              ' %s ',
              c.use_icons and f.kind or f.kind:sub(1, 1)
            )
            return f
          end,
        },
        window = {
          completion = {
            col_offset = -3,
            side_padding = 0,
          },
        },
        performance = {
          -- debounce = 200,
        },
      }

      k.s('<Tab>', snip.keyseq_s_jump_next, { expr = true })
      k.s('<S-Tab>', snip.keyseq_s_jump_prev, { expr = true })

      local ok, cmp_autopairs =
        pcall(require, 'nvim-autopairs.completion.cmp')
      if ok then
        cmp.event:on(
          'confirm_done',
          cmp_autopairs.on_confirm_done {
            map_char = { tex = '' },
          }
        )
      end
    end,
  },
  { 'hrsh7th/cmp-nvim-lsp', lazy = true },
  { 'hrsh7th/cmp-buffer', lazy = true },
  { 'hrsh7th/cmp-path', lazy = true },
  { 'hrsh7th/cmp-cmdline', lazy = true },
  { 'quangnguyen30192/cmp-nvim-ultisnips', lazy = true },
  { 'onsails/lspkind.nvim', lazy = true },
  {
    'SirVer/ultisnips',
    dependencies = { 'vim-snippets', 'vim-emmet-ultisnips' },
    lazy = true,
    init = function()
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
    config = function()
      ac.augroup('rc__unregister_ultisnips_autotrigger', function(au)
        au('VimEnter', '*', function()
          vim.cmd [[autocmd! UltiSnips_AutoTrigger]]
        end)
      end)
    end,
  },
  { 'honza/vim-snippets', lazy = true },
  { 'adriaanzon/vim-emmet-ultisnips', lazy = true },
}
