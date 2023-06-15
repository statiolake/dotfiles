return {
  {
    'iamcco/markdown-preview.nvim',
    on_ft = { 'markdown' },
    after_load = function()
      vim.fn['mkdp#util#install']()
    end,
  },
}
