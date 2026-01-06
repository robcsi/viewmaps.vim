-- viewmaps.nvim plugin loader
-- Auto-executed on startup

if vim.g.loaded_viewmaps then
  return
end
vim.g.loaded_viewmaps = true

-- Require Neovim 0.8+ for floating window features
if vim.fn.has('nvim-0.8') == 0 then
  vim.notify('viewmaps.nvim requires Neovim 0.8 or higher', vim.log.levels.ERROR)
  return
end

-- Create user commands
vim.api.nvim_create_user_command('ViewMaps', function(opts)
  local mode = opts.args ~= '' and opts.args or 'n'
  require('viewmaps').show(mode)
end, {
  nargs = '?',
  desc = 'Show keymappings in floating window',
  complete = function()
    return { 'n', 'i', 'v', 'x', 's', 'o', 'c', 't' }
  end,
})

vim.api.nvim_create_user_command('ViewMapsToggle', function(opts)
  local mode = opts.args ~= '' and opts.args or 'n'
  require('viewmaps').toggle(mode)
end, {
  nargs = '?',
  desc = 'Toggle keymappings floating window',
  complete = function()
    return { 'n', 'i', 'v', 'x', 's', 'o', 'c', 't' }
  end,
})

vim.api.nvim_create_user_command('ViewMapsClose', function()
  require('viewmaps').close()
end, {
  desc = 'Close keymappings floating window',
})
