local use_icons = get_global_config 'ui.useIcons'

return {
  {
    'nvim-lua/plenary.nvim',
    lazy = true,
  },
  {
    'nvim-lua/popup.nvim',
    lazy = true,
  },
  {
    'kyazdani42/nvim-web-devicons',
    enabled = use_icons,
    lazy = true,
  },
  {
    'ryanoasis/vim-devicons',
    enabled = use_icons,
    lazy = true,
  },
  {
    'rktjmp/lush.nvim',
    lazy = true,
  },
  {
    'vim-denops/denops.vim',
    lazy = true,
  },
}
