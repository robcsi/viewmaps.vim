-- viewmaps.nvim configuration
local M = {}

M.defaults = {
  window = {
    width = 0.8,      -- percentage of editor width (0-1) or fixed columns
    height = 0.8,     -- percentage of editor height (0-1) or fixed rows
    border = 'rounded', -- 'rounded', 'single', 'double', 'solid', 'shadow', 'none'
    title = ' ViewMaps ',
    title_pos = 'center',
  },
  show_desc = true,       -- show mapping descriptions
  show_no_desc = true,    -- show mappings without descriptions
  filter_plugins = false, -- hide plugin mappings (those with <Plug>)
  sort_by = 'lhs',        -- 'lhs', 'desc', or 'none'
  modes = { 'n', 'i', 'v', 'x', 's', 'o', 'c', 't' },
  mode_names = {
    n = 'Normal',
    i = 'Insert',
    v = 'Visual',
    x = 'Visual Block',
    s = 'Select',
    o = 'Operator',
    c = 'Command',
    t = 'Terminal',
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

function M.get()
  if vim.tbl_isempty(M.options) then
    M.setup({})
  end
  return M.options
end

return M
