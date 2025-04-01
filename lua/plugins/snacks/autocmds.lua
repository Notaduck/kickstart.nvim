-- lua/plugins/snacks/autocmds.lua
local M = {}

function M.setup()
  -- Disable all animations by default
  vim.g.snacks_animate = false

  -- Re-enable the dimming animation specifically when VeryLazy is triggered
  vim.api.nvim_create_autocmd('User', {
    pattern = 'VeryLazy',
    callback = function()
      local dimming_key = 'snacks_animate_dimming_effect'
      vim.b[dimming_key] = true
      vim.keymap.set('n', '<leader>uD', function()
        Snacks.toggle.dim()
      end, { desc = 'Toggle Dimming Animation' })
    end,
  })
end

return M
