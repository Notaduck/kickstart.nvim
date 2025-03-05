return {
  -- Plugin specifications
  { import = 'plugins.lsp' },
  { import = 'plugins.completion' },
  { import = 'plugins.ui' },
  
  -- Basic plugins
  'tpope/vim-sleuth',
  { 'folke/which-key.nvim', event = 'VimEnter' },
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },
  
  -- Load recommended plugin configurations
  { import = 'kickstart.plugins.indent_line' },
  { import = 'kickstart.plugins.gitsigns' },
}
