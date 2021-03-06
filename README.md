# ViewMaps.vim
Small plugin for displaying mappings defined in vimrc

![](viewmaps.jpg?raw=true)

## Motivation
The plugin was born as an exercise with Vimscript to aid me in remembering my mappings in VIm, browsing them without having to open the vimrc all the time, and it's my first plugin.

## Purpose
You can use this plugin to populate a list of your vimrc mappings in the 
QuickFix window.
The mappings can be retrieved by VIm mode types (like normal, insert, visual,
select and operator-pending mode).

The `:map` command displays all availabe and loaded mappings in VIm and that
list contains too much to process just by looking at it. This plugin helps
you view only the ones defined by you with comments related to them.

Mappings can be many, this is why filtering is possible for different modes.
By populating the QuickFix window you can quickly jump to the vimrc
file on the exact line where the mappings are defined.
Comments are also displayed: currently it only displays one line comments from
the line right above the mappings or comments at the end of the mapping line,
starting with the last available `"` character to the end of the line.

Get the plugin from here on Github: https://github.com/robcsi/viewmaps.vim.git

You can use Pathogen to include it into your plugin bundle.

Other features include:
- The plugin tries to detect rc files that are sourced in your main
vimrc. Only lines starting with 'source' are parsed and mappings loaded
from those files, too

- Mappings can be displayed in the Quickfix window or an echoed list, like the 'map' command
does, just for quick reference. The display formatting is different
in this case, compared to the QuickFix format

- In the Quickfix window (leveraging its functionality) you can press
<Enter> and go to the selected line in the main or sourced vimrc file.
There you can edit the mapping or its comment as desired and maybe
reload the list of mappings into the QuickFix window
	
- There is an option for configuring the position of the QuickFix window,
`g:viewmaps_quickfix_orientation` (horizontal or vertical)

- There is an option for configuring the width or height of the Quickfix
window depending on what its position is: `g:viewmaps_quickfix_dimension`

- The plugin leverages the functionality of the QuickFix window by using
jumping to lines in the rc files, also leverages the `[q` and `]q` et.al.
keyboard shortcuts defined by the [vim-unimpaired](https://github.com/tpope/vim-unimpaired) plugin
    
For more information read the help file. :h viewmaps

## Version
0.1.0

## Copyright - 2016
Robert Sarkozi
