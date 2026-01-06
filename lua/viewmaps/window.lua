-- viewmaps.nvim floating window UI
local config = require('viewmaps.config')
local mappings = require('viewmaps.mappings')

local M = {}

local state = {
  buf = nil,
  win = nil,
  current_mode = 'n',
}

local ns_id = vim.api.nvim_create_namespace('viewmaps')

--- Calculate window dimensions
---@return table Window options for nvim_open_win
local function get_win_opts()
  local opts = config.get()
  local win_opts = opts.window

  local editor_width = vim.o.columns
  local editor_height = vim.o.lines

  local width = win_opts.width
  local height = win_opts.height

  -- Convert percentage to absolute if needed
  if width <= 1 then
    width = math.floor(editor_width * width)
  end
  if height <= 1 then
    height = math.floor(editor_height * height)
  end

  -- Calculate centered position
  local row = math.floor((editor_height - height) / 2)
  local col = math.floor((editor_width - width) / 2)

  return {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = win_opts.border,
    title = win_opts.title,
    title_pos = win_opts.title_pos,
  }
end

--- Create mode tabs header
---@param current_mode string Currently selected mode
---@return string Header line
---@return table[] Highlight positions {col_start, col_end, hl_group}
local function create_mode_tabs(current_mode)
  local opts = config.get()
  local modes = opts.modes
  local parts = {}
  local highlights = {}
  local col = 2 -- start after initial padding

  for i, mode in ipairs(modes) do
    local mode_name = opts.mode_names[mode] or mode
    local short_name = mode:upper()

    if mode == current_mode then
      table.insert(parts, '[' .. short_name .. ']')
      table.insert(highlights, { col, col + #short_name + 2, 'ViewMapsActiveMode' })
    else
      table.insert(parts, ' ' .. short_name .. ' ')
      table.insert(highlights, { col, col + #short_name + 2, 'ViewMapsMode' })
    end

    col = col + #short_name + 3 -- mode char + brackets/spaces + space

    if i < #modes then
      table.insert(parts, ' ')
      col = col + 1
    end
  end

  local header = '  ' .. table.concat(parts, '')
  local mode_name = opts.mode_names[current_mode] or current_mode
  local count_str = ''

  return header, highlights, mode_name
end

--- Set up buffer keymaps
local function setup_keymaps()
  local buf = state.buf
  local opts = { buffer = buf, noremap = true, silent = true }

  -- Close window
  vim.keymap.set('n', 'q', function() M.close() end, opts)
  vim.keymap.set('n', '<Esc>', function() M.close() end, opts)

  -- Mode switching with number keys
  local modes = config.get().modes
  for i, mode in ipairs(modes) do
    if i <= 9 then
      vim.keymap.set('n', tostring(i), function()
        M.switch_mode(mode)
      end, opts)
    end
  end

  -- Mode switching with brackets
  vim.keymap.set('n', ']m', function() M.next_mode() end, opts)
  vim.keymap.set('n', '[m', function() M.prev_mode() end, opts)
  vim.keymap.set('n', '<Tab>', function() M.next_mode() end, opts)
  vim.keymap.set('n', '<S-Tab>', function() M.prev_mode() end, opts)

  -- Refresh
  vim.keymap.set('n', 'r', function() M.refresh() end, opts)
end

--- Set up highlights
local function setup_highlights()
  vim.api.nvim_set_hl(0, 'ViewMapsActiveMode', { link = 'Title', default = true })
  vim.api.nvim_set_hl(0, 'ViewMapsMode', { link = 'Comment', default = true })
  vim.api.nvim_set_hl(0, 'ViewMapsHeader', { link = 'Title', default = true })
  vim.api.nvim_set_hl(0, 'ViewMapsKey', { link = 'Keyword', default = true })
  vim.api.nvim_set_hl(0, 'ViewMapsDesc', { link = 'String', default = true })
  vim.api.nvim_set_hl(0, 'ViewMapsFooter', { link = 'Comment', default = true })
end

--- Render the buffer content
local function render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  local opts = config.get()
  local mode = state.current_mode
  local lines = {}

  -- Header with mode tabs
  local header, header_hl, mode_name = create_mode_tabs(mode)
  table.insert(lines, header)
  table.insert(lines, '')

  -- Mode info
  local map_lines, count = mappings.format_all(mode)
  local info_line = string.format('  %s Mode - %d mapping(s)', mode_name, count)
  table.insert(lines, info_line)
  table.insert(lines, string.rep('─', 50))
  table.insert(lines, '')

  -- Mappings
  for _, line in ipairs(map_lines) do
    table.insert(lines, line)
  end

  -- Footer
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 50))
  table.insert(lines, '  q:close  1-8:mode  Tab/]m:next  r:refresh')

  -- Set buffer content
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)

  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(state.buf, ns_id, 0, -1)

  -- Highlight mode tabs
  for _, hl in ipairs(header_hl) do
    vim.api.nvim_buf_add_highlight(state.buf, ns_id, hl[3], 0, hl[1], hl[2])
  end

  -- Highlight info line
  vim.api.nvim_buf_add_highlight(state.buf, ns_id, 'ViewMapsHeader', 2, 0, -1)

  -- Highlight footer
  vim.api.nvim_buf_add_highlight(state.buf, ns_id, 'ViewMapsFooter', #lines - 1, 0, -1)
end

--- Open the floating window
---@param mode? string Initial mode to display (default: 'n')
function M.open(mode)
  setup_highlights()

  state.current_mode = mode or 'n'

  -- Create buffer
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(state.buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(state.buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(state.buf, 'filetype', 'viewmaps')

  -- Create window
  local win_opts = get_win_opts()
  state.win = vim.api.nvim_open_win(state.buf, true, win_opts)

  -- Window options
  vim.api.nvim_win_set_option(state.win, 'cursorline', true)
  vim.api.nvim_win_set_option(state.win, 'wrap', false)

  -- Set up keymaps and render
  setup_keymaps()
  render()

  -- Auto-close on leave
  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = state.buf,
    once = true,
    callback = function()
      M.close()
    end,
  })
end

--- Close the floating window
function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.buf = nil
end

--- Toggle the floating window
---@param mode? string Mode to display
function M.toggle(mode)
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    M.open(mode)
  end
end

--- Switch to a specific mode
---@param mode string Mode character
function M.switch_mode(mode)
  state.current_mode = mode
  render()
end

--- Switch to next mode
function M.next_mode()
  local modes = config.get().modes
  local current_idx = 1
  for i, m in ipairs(modes) do
    if m == state.current_mode then
      current_idx = i
      break
    end
  end
  local next_idx = (current_idx % #modes) + 1
  M.switch_mode(modes[next_idx])
end

--- Switch to previous mode
function M.prev_mode()
  local modes = config.get().modes
  local current_idx = 1
  for i, m in ipairs(modes) do
    if m == state.current_mode then
      current_idx = i
      break
    end
  end
  local prev_idx = ((current_idx - 2) % #modes) + 1
  M.switch_mode(modes[prev_idx])
end

--- Refresh current view
function M.refresh()
  render()
end

--- Check if window is open
---@return boolean
function M.is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

return M
