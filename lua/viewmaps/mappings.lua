-- viewmaps.nvim mapping retrieval and formatting
local config = require('viewmaps.config')

local M = {}

--- Get all mappings for a given mode
---@param mode string Single character mode ('n', 'i', 'v', etc.)
---@return table[] List of mapping objects
function M.get_mappings(mode)
  local opts = config.get()
  local maps = vim.api.nvim_get_keymap(mode)

  -- Also get buffer-local mappings
  local buf_maps = vim.api.nvim_buf_get_keymap(0, mode)
  for _, map in ipairs(buf_maps) do
    map.buffer_local = true
    table.insert(maps, map)
  end

  -- Filter mappings
  local filtered = {}
  for _, map in ipairs(maps) do
    local include = true

    -- Filter <Plug> mappings if configured
    if opts.filter_plugins and map.lhs:match('<Plug>') then
      include = false
    end

    -- Filter mappings without description if configured
    if not opts.show_no_desc and (not map.desc or map.desc == '') then
      include = false
    end

    if include then
      table.insert(filtered, map)
    end
  end

  -- Sort mappings
  if opts.sort_by == 'lhs' then
    table.sort(filtered, function(a, b)
      return a.lhs < b.lhs
    end)
  elseif opts.sort_by == 'desc' then
    table.sort(filtered, function(a, b)
      local desc_a = a.desc or ''
      local desc_b = b.desc or ''
      return desc_a < desc_b
    end)
  end

  return filtered
end

--- Format a single mapping for display
---@param map table Mapping object from nvim_get_keymap
---@param max_lhs_width number Maximum width for lhs column
---@return string Formatted line
function M.format_mapping(map, max_lhs_width)
  local lhs = map.lhs
  local desc = map.desc or map.rhs or ''

  -- Truncate long descriptions
  local max_desc = 60
  if #desc > max_desc then
    desc = desc:sub(1, max_desc - 3) .. '...'
  end

  -- Pad lhs to align descriptions
  local padding = string.rep(' ', max_lhs_width - #lhs + 2)

  local suffix = ''
  if map.buffer_local then
    suffix = ' [buf]'
  end

  return string.format('  %s%s%s%s', lhs, padding, desc, suffix)
end

--- Format all mappings for a mode
---@param mode string Single character mode
---@return string[] List of formatted lines
---@return number Count of mappings
---@return table[] Raw mapping objects (parallel to lines)
function M.format_all(mode)
  local maps = M.get_mappings(mode)
  local lines = {}

  if #maps == 0 then
    return { '', '  No mappings found for this mode', '' }, 0, {}
  end

  -- Calculate max lhs width for alignment
  local max_lhs = 0
  for _, map in ipairs(maps) do
    if #map.lhs > max_lhs then
      max_lhs = #map.lhs
    end
  end

  -- Format each mapping
  for _, map in ipairs(maps) do
    table.insert(lines, M.format_mapping(map, max_lhs))
  end

  return lines, #maps, maps
end

--- Get source location for a mapping
---@param map table Mapping object
---@return string|nil file File path or nil
---@return number|nil lnum Line number or nil
function M.get_source_location(map)
  if not map.sid or map.sid <= 0 then
    return nil, nil
  end

  local script_info = vim.fn.getscriptinfo({ sid = map.sid })
  if not script_info or not script_info[1] then
    return nil, nil
  end

  local file = script_info[1].name
  local lnum = (map.lnum and map.lnum > 0) and map.lnum or nil

  return file, lnum
end

--- Search for mapping definition in file
---@param file string File path
---@param lhs string Left-hand side of mapping
---@return number|nil Line number where found
function M.find_mapping_in_file(file, lhs)
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then
    return nil
  end

  -- Escape special pattern characters in lhs
  local escaped_lhs = lhs:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')
  -- Also try with <leader> variations
  local patterns = {
    escaped_lhs,
    escaped_lhs:gsub(' ', '<[Ll]eader>'),
    escaped_lhs:gsub(' ', '<[Ss]pace>'),
  }

  for i, line in ipairs(lines) do
    for _, pattern in ipairs(patterns) do
      if line:match(pattern) then
        return i
      end
    end
  end

  return nil
end

return M
