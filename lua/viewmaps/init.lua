-- viewmaps.nvim - Display keymappings in a floating window
-- A Neovim plugin for viewing your keymappings by mode

local M = {}

--- Setup viewmaps with user options
---@param opts? table Configuration options
function M.setup(opts)
  require('viewmaps.config').setup(opts)
end

--- Show mappings in floating window
---@param mode? string Mode to display ('n', 'i', 'v', etc.) - defaults to 'n'
function M.show(mode)
  require('viewmaps.window').open(mode)
end

--- Toggle the floating window
---@param mode? string Mode to display
function M.toggle(mode)
  require('viewmaps.window').toggle(mode)
end

--- Close the floating window
function M.close()
  require('viewmaps.window').close()
end

--- Check if window is currently open
---@return boolean
function M.is_open()
  return require('viewmaps.window').is_open()
end

return M
