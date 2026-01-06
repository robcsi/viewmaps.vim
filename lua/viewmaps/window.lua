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

  -- Border with highlight group
  local border = win_opts.border
  if type(border) == 'string' and border ~= 'none' then
    -- Convert string border to table with highlight
    local border_chars = {
      none = {},
      single = { '┌', '─', '┐', '│', '┘', '─', '└', '│' },
      double = { '╔', '═', '╗', '║', '╝', '═', '╚', '║' },
      rounded = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
      solid = { '▛', '▀', '▜', '▐', '▟', '▄', '▙', '▌' },
      shadow = { '', '', ' ', ' ', ' ', ' ', ' ', '' },
    }
    local chars = border_chars[border] or border_chars.rounded
    border = {}
    for _, char in ipairs(chars) do
      table.insert(border, { char, 'ViewMapsBorder' })
    end
  end

  return {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = border,
  }
end

--- Create mode tabs string for window title
---@param current_mode string Currently selected mode
---@return string Title string
local function create_title(current_mode)
  local opts = config.get()
  local modes = opts.modes
  local parts = {}

  for _, mode in ipairs(modes) do
    local short_name = mode:upper()
    if mode == current_mode then
      table.insert(parts, '[' .. short_name .. ']')
    else
      table.insert(parts, ' ' .. short_name .. ' ')
    end
  end

  return ' ' .. table.concat(parts, ' ') .. ' '
end

--- Create winbar string with mode info
---@param current_mode string Currently selected mode
---@param count number Number of mappings
---@return string Winbar string with highlights
local function create_winbar(current_mode, count)
  local opts = config.get()
  local mode_name = opts.mode_names[current_mode] or current_mode
  return string.format('  %%#ViewMapsHeader#%s Mode%%* - %d mapping(s)', mode_name, count)
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
  vim.api.nvim_set_hl(0, 'ViewMapsBorder', { fg = '#ffffff', default = true })
end

--- Render the buffer content
local function render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then
    return
  end

  local mode = state.current_mode
  local lines = {}

  -- Get mappings
  local map_lines, count = mappings.format_all(mode)

  -- Set window title with mode tabs
  local title = create_title(mode)
  vim.api.nvim_win_set_config(state.win, { title = title, title_pos = 'center' })

  -- Set winbar with mode info (fixed below title)
  local winbar = create_winbar(mode, count)
  vim.api.nvim_set_option_value('winbar', winbar, { win = state.win })

  -- Mappings only (no footer in buffer - it's in statusline)
  for _, line in ipairs(map_lines) do
    table.insert(lines, line)
  end

  -- Set statusline as fixed footer
  local statusline = '%#ViewMapsFooter#  q:close  1-8:mode  Tab/]m:next  r:refresh%*'
  vim.api.nvim_set_option_value('statusline', statusline, { win = state.win })

  -- Set buffer content
  vim.api.nvim_set_option_value('modifiable', true, { buf = state.buf })
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = state.buf })

  -- Clear any old highlights
  vim.api.nvim_buf_clear_namespace(state.buf, ns_id, 0, -1)
end

--- Open the floating window
---@param mode? string Initial mode to display (default: 'n')
function M.open(mode)
  setup_highlights()

  state.current_mode = mode or 'n'

  -- Create buffer
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = state.buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = state.buf })
  vim.api.nvim_set_option_value('filetype', 'viewmaps', { buf = state.buf })

  -- Create window
  local win_opts = get_win_opts()
  state.win = vim.api.nvim_open_win(state.buf, true, win_opts)

  -- Window options
  vim.api.nvim_set_option_value('cursorline', true, { win = state.win })
  vim.api.nvim_set_option_value('wrap', false, { win = state.win })
  vim.api.nvim_set_option_value('number', false, { win = state.win })
  vim.api.nvim_set_option_value('relativenumber', false, { win = state.win })
  vim.api.nvim_set_option_value('winfixheight', true, { win = state.win })

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
