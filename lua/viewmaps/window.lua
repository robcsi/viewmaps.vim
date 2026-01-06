-- viewmaps.nvim floating window UI
local config = require('viewmaps.config')
local mappings = require('viewmaps.mappings')

local M = {}

local state = {
  buf = nil,
  win = nil,
  footer_buf = nil,
  footer_win = nil,
  current_mode = 'n',
  current_maps = {}, -- mapping objects indexed by buffer line
}

local ns_id = vim.api.nvim_create_namespace('viewmaps')

--- Create border with highlight group
local function make_border(border_style)
  if type(border_style) ~= 'string' or border_style == 'none' then
    return border_style
  end
  local border_chars = {
    single = { '┌', '─', '┐', '│', '┘', '─', '└', '│' },
    double = { '╔', '═', '╗', '║', '╝', '═', '╚', '║' },
    rounded = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
    solid = { '▛', '▀', '▜', '▐', '▟', '▄', '▙', '▌' },
  }
  local chars = border_chars[border_style] or border_chars.rounded
  local border = {}
  for _, char in ipairs(chars) do
    table.insert(border, { char, 'ViewMapsBorder' })
  end
  return border
end

--- Calculate window dimensions
---@return table main_opts, table footer_opts
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

  -- Reserve 1 row for footer + separator
  local footer_height = 1
  local main_height = height - footer_height - 1 -- -1 for separator line

  -- Calculate centered position
  local row = math.floor((editor_height - height) / 2)
  local col = math.floor((editor_width - width) / 2)

  local border = make_border(win_opts.border)

  -- Main window: top and sides, bottom connects to footer
  local main_border = {
    border[1], border[2], border[3], -- top-left, top, top-right
    border[4],                        -- right
    { '┤', 'ViewMapsBorder' }, { '─', 'ViewMapsBorder' }, { '├', 'ViewMapsBorder' }, -- bottom connects
    border[8],                        -- left
  }

  -- Footer window: sides and bottom, top is open
  local footer_border = {
    { '', 'ViewMapsBorder' }, { '', 'ViewMapsBorder' }, { '', 'ViewMapsBorder' }, -- no top
    border[4], border[5], border[6], border[7], border[8],
  }

  local main_opts = {
    relative = 'editor',
    width = width,
    height = main_height,
    row = row,
    col = col,
    style = 'minimal',
    border = main_border,
  }

  local footer_opts = {
    relative = 'editor',
    width = width,
    height = footer_height,
    row = row + main_height + 2, -- +2 for main border
    col = col,
    style = 'minimal',
    border = footer_border,
    focusable = false,
  }

  return main_opts, footer_opts
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

--- Jump to mapping definition
local function jump_to_definition()
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local line_nr = cursor[1]

  local map = state.current_maps[line_nr]
  if not map then
    vim.notify('No mapping on this line', vim.log.levels.WARN)
    return
  end

  local file, lnum = mappings.get_source_location(map)
  if not file then
    vim.notify('No source location available for this mapping', vim.log.levels.WARN)
    return
  end

  -- If no line number, try to find it by searching
  if not lnum then
    lnum = mappings.find_mapping_in_file(file, map.lhs)
  end

  -- Close the window first
  M.close()

  -- Open the file
  vim.cmd('edit ' .. vim.fn.fnameescape(file))

  -- Jump to line if we have one
  if lnum then
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
    vim.cmd('normal! zz')
  else
    -- Search for the mapping
    local search_pattern = vim.fn.escape(map.lhs, '/\\')
    vim.fn.setreg('/', search_pattern)
    vim.notify('Opened file, search for: ' .. map.lhs, vim.log.levels.INFO)
  end
end

--- Set up buffer keymaps
local function setup_keymaps()
  local buf = state.buf
  local opts = { buffer = buf, noremap = true, silent = true }

  -- Close window
  vim.keymap.set('n', 'q', function() M.close() end, opts)
  vim.keymap.set('n', '<Esc>', function() M.close() end, opts)

  -- Jump to definition
  vim.keymap.set('n', '<CR>', jump_to_definition, opts)

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
  local map_lines, count, maps = mappings.format_all(mode)

  -- Set window title with mode tabs
  local title = create_title(mode)
  vim.api.nvim_win_set_config(state.win, { title = title, title_pos = 'center' })

  -- Set winbar with mode info (fixed below title)
  local winbar = create_winbar(mode, count)
  vim.api.nvim_set_option_value('winbar', winbar, { win = state.win })

  -- Store mapping objects indexed by line number for jump-to-definition
  state.current_maps = {}
  for i, map in ipairs(maps) do
    state.current_maps[i] = map
  end

  -- Mappings
  for _, line in ipairs(map_lines) do
    table.insert(lines, line)
  end

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

  -- Create main buffer
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = state.buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = state.buf })
  vim.api.nvim_set_option_value('filetype', 'viewmaps', { buf = state.buf })

  -- Create footer buffer
  state.footer_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = state.footer_buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = state.footer_buf })
  vim.api.nvim_buf_set_lines(state.footer_buf, 0, -1, false, {
    '  Enter:goto  q:close  1-8:mode  Tab:next  r:refresh'
  })

  -- Create windows
  local main_opts, footer_opts = get_win_opts()
  state.win = vim.api.nvim_open_win(state.buf, true, main_opts)
  state.footer_win = vim.api.nvim_open_win(state.footer_buf, false, footer_opts)

  -- Main window options
  vim.api.nvim_set_option_value('cursorline', true, { win = state.win })
  vim.api.nvim_set_option_value('wrap', false, { win = state.win })
  vim.api.nvim_set_option_value('number', false, { win = state.win })
  vim.api.nvim_set_option_value('relativenumber', false, { win = state.win })

  -- Footer window options
  vim.api.nvim_set_option_value('wrap', false, { win = state.footer_win })

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
  if state.footer_win and vim.api.nvim_win_is_valid(state.footer_win) then
    vim.api.nvim_win_close(state.footer_win, true)
  end
  state.win = nil
  state.buf = nil
  state.footer_win = nil
  state.footer_buf = nil
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
