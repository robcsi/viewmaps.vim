# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

viewmaps.nvim is a Neovim plugin written in Lua that displays keymappings in a floating window, organized by mode. It shows mapping descriptions from the `desc` field and supports lazy.nvim/LazyVim.

## Architecture

```
lua/viewmaps/
├── init.lua       # Public API: setup(), show(), toggle(), close()
├── config.lua     # Default configuration and option merging
├── mappings.lua   # Mapping retrieval via nvim_get_keymap, formatting
└── window.lua     # Floating window UI, mode tabs, keybindings
plugin/
└── viewmaps.lua   # User commands (:ViewMaps, :ViewMapsToggle, :ViewMapsClose)
```

### Key Components

- **config.lua**: Stores defaults and merged user options. Access via `config.get()`
- **mappings.lua**: `get_mappings(mode)` retrieves keymaps, `format_all(mode)` formats for display
- **window.lua**: Manages floating window state, mode tabs, buffer keymaps (q, Tab, 1-8)
- **init.lua**: Thin wrapper exposing public API, lazy-loads other modules

## Testing

No automated tests. Test manually in Neovim:
```vim
:ViewMaps n        " Show normal mode mappings
:ViewMaps i        " Show insert mode mappings
```

## Commands

- `:ViewMaps [mode]` - Open floating window (default: 'n')
- `:ViewMapsToggle [mode]` - Toggle window
- `:ViewMapsClose` - Close window

Modes: n, i, v, x, s, o, c, t

## Configuration

```lua
require('viewmaps').setup({
  window = { width = 0.8, height = 0.8, border = 'rounded' },
  show_desc = true,
  filter_plugins = false,
})
```
