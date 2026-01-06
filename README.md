# viewmaps.nvim

A Neovim plugin for displaying your keymappings in a floating window, organized by mode.

![viewmaps.nvim](viewmaps.jpg?raw=true)

## Features

- View keymappings in a modern floating window
- Filter by mode (Normal, Insert, Visual, etc.)
- Shows mapping descriptions (from `desc` field)
- Switch between modes with Tab or number keys
- Works with lazy.nvim and LazyVim

## Requirements

- Neovim >= 0.8

## Installation

### lazy.nvim

```lua
{
  'robcsi/viewmaps.nvim',
  cmd = { 'ViewMaps', 'ViewMapsToggle' },
  keys = {
    { '<leader>vm', '<cmd>ViewMaps n<CR>', desc = 'View Normal Mappings' },
    { '<leader>vi', '<cmd>ViewMaps i<CR>', desc = 'View Insert Mappings' },
    { '<leader>vv', '<cmd>ViewMaps v<CR>', desc = 'View Visual Mappings' },
  },
  opts = {},
}
```

### packer.nvim

```lua
use {
  'robcsi/viewmaps.nvim',
  config = function()
    require('viewmaps').setup()
  end
}
```

## Usage

### Commands

```vim
:ViewMaps [mode]       " Open floating window with mappings for mode (default: n)
:ViewMapsToggle [mode] " Toggle the floating window
:ViewMapsClose         " Close the floating window
```

### Modes

| Mode | Character | Description |
|------|-----------|-------------|
| Normal | `n` | Normal mode mappings |
| Insert | `i` | Insert mode mappings |
| Visual | `v` | Visual mode mappings |
| Visual Block | `x` | Visual block mode mappings |
| Select | `s` | Select mode mappings |
| Operator | `o` | Operator-pending mode mappings |
| Command | `c` | Command-line mode mappings |
| Terminal | `t` | Terminal mode mappings |

### Window Keybindings

| Key | Action |
|-----|--------|
| `q` / `<Esc>` | Close window |
| `1-8` | Switch to mode (by position) |
| `Tab` / `]m` | Next mode |
| `Shift-Tab` / `[m` | Previous mode |
| `r` | Refresh mappings |

## Configuration

```lua
require('viewmaps').setup({
  window = {
    width = 0.8,          -- 80% of editor width
    height = 0.8,         -- 80% of editor height
    border = 'rounded',   -- 'rounded', 'single', 'double', 'solid', 'shadow', 'none'
    title = ' ViewMaps ',
    title_pos = 'center',
  },
  show_desc = true,       -- show mapping descriptions
  show_no_desc = true,    -- show mappings without descriptions
  filter_plugins = false, -- hide <Plug> mappings
  sort_by = 'lhs',        -- 'lhs', 'desc', or 'none'
})
```

## Lua API

```lua
local viewmaps = require('viewmaps')

viewmaps.setup(opts)  -- Configure plugin
viewmaps.show('n')    -- Show normal mode mappings
viewmaps.toggle('v')  -- Toggle visual mode mappings
viewmaps.close()      -- Close window
viewmaps.is_open()    -- Check if window is open
```

## Tips

For best results, add `desc` to your keymappings:

```lua
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>', {
  desc = 'Find files'
})
```

## License

This file is placed in the public domain.

## Author

Robert Sarkozi
