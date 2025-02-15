vim.defer_fn(function()
  local cmp_ok, cmp = pcall(require, 'cmp')
  if not cmp_ok then
    return
  end

  -- Retrieve the current mapping table (set by Kickstart)
  local current_mapping = cmp.get_config().mapping or {}

  -- Define the overrides using the old config's working mappings:
  local override = {
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
  }

  -- Merge your overrides with the existing mappings.
  local new_mapping = vim.tbl_deep_extend('force', current_mapping, override)

  -- Reconfigure cmp to use the updated mapping table.
  cmp.setup { mapping = new_mapping }

  print 'Custom <Tab>/<S-Tab> mappings applied'
end, 500)
