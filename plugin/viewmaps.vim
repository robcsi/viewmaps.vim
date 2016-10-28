
" Vim global plugin for displaying mappings from your vimrc
" Last Change:	2016 Oct. 24
" Maintainer:	Robert Sarkozi <sarkozi.robert@gmail.com>
" License:	This file is placed in the public domain.
" Version:	0.1.0

if exists("g:loaded_viewmaps")
  finish
endif
let g:loaded_viewmaps = 1

let s:save_cpo = &cpo
set cpo&vim

"The functionality BEGIN ++++++++++++++++++++++++++++++++++++++++++

" GetConfigFiles - gets vimrc and files sourced by it and returns
" them in a list
function! s:GetConfigFiles()
  let s:vimrc = expand("$MYVIMRC")

  let s:sourcedRCFiles = add([], s:vimrc)
  let s:vimrcLines = readfile(s:vimrc)

  for s:rcFile in s:vimrcLines
    if s:rcFile =~ "^source"
      let s:parts = split(s:rcFile)
      let s:sourcedRCFiles = add(s:sourcedRCFiles, get(s:parts, 1))
    endif
  endfor

  return s:sourcedRCFiles

endfunction

" list of mapping modes - the six major ones
let s:mappingTypes = ['n', 'i', 'v', 's', 'o', 'c']

" see :h map-overview, map-modes for list of modes and their mappings
let s:normalModeMapCommands = ['map', 'nm', 'nn']
let s:insertModeMapCommands = ['im', 'ino']
let s:visualModeMapCommands = ['map', 'vm', 'vno', 'smap', 'snor', 'xmap', 'xno']
let s:selectModeMapCommands = ['map', 'smap', 'snor', 'vm', 'vno']
let s:operatorpendingModeMapCommands = ['map', 'om', 'ono']
let s:commandlineModeMapCommands = ['cm', 'cno']

" dictionary of mapping modes and their lists of mappings
let s:mappingModesMap = {'n' : s:normalModeMapCommands, 
                        \'i' : s:insertModeMapCommands, 
                        \'v' : s:visualModeMapCommands, 
                        \'s' : s:selectModeMapCommands, 
                        \'o' : s:operatorpendingModeMapCommands, 
                        \'c' : s:commandlineModeMapCommands }

" DisplayMappings - displays all the mappings, filtered by parameters
function! s:DisplayMappings(mappingMode)

  let s:files = s:GetConfigFiles()

  "get commands of selected mode
  let s:mapCommands = s:mappingModesMap[a:mappingMode]

  for s:file in s:files
    echo 'RC File: '.s:file."\n"
    let s:linesInFile = readfile(s:file)
    let s:lineCount = len(s:linesInFile)
    let s:lineIndex = 0

    while s:lineIndex < s:lineCount
      for s:mapCommand in s:mapCommands

        let s:line = get(s:linesInFile, s:lineIndex, '')

        "display mapping
        if strlen(s:line) > 0 
          if s:line =~ '^'.s:mapCommand 
            "display comment if available
            if s:lineIndex > 0
              let s:previousLine = get(s:linesInFile, s:lineIndex - 1, '')
              if s:previousLine =~ '^"'
                echo (s:lineIndex - 1).': '.s:previousLine
              endif
            endif

            "display mapping line
            echo s:lineIndex.': '.s:line 

            "display empty line
            echo "\n"
          endif
        endif
      endfor

      let s:lineIndex += 1
    endwhile
  endfor
endfunction

"The functionality END ++++++++++++++++++++++++++++++++++++++++++++

"the new way
if !exists('g:viewmaps_map_keys')
    let g:viewmaps_map_keys = 1
endif

if g:viewmaps_map_keys
    nnoremap <leader>d :call <sid>DisplayMappings()<CR>
endif

"the old way (help)
if !hasmapto('<Plug>ViewmapsReadfile')
  map <unique> <Leader>M  <Plug>ViewmapsReadfile
endif
noremap <unique> <script> <Plug>ViewmapsReadfile  <SID>DisplayMappings

noremap <Plug>DisplayMappings  :call <SID>DisplayMappings()<CR>

if !exists(":ViewMaps")
  command! -nargs=1 ViewMaps :call s:DisplayMappings(<q-args>)
endif

let &cpo = s:save_cpo
unlet s:save_cpo
