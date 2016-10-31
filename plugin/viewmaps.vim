
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

" dictionary of mapping modes and their names
let s:mappingModeNamesMap = {'n' : 'Normal Mode', 
                            \'i' : 'Insert Mode', 
                            \'v' : 'Visual Mode', 
                            \'s' : 'Select Mode', 
                            \'o' : 'Operator-Pending Mode', 
                            \'c' : 'Command Line Mode' }

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

" GetMappingsFor - gathers all the mappings, filtered by parameters
function! s:GetMappingsFor(mappingMode)

  "get commands of selected mode
  let s:mapCommands = s:mappingModesMap[a:mappingMode]

  let s:result = add([], s:mappingModeNamesMap[a:mappingMode].' mappings: '.join(s:mapCommands, ', '))
  let s:result = add(s:result, s:CreateUnderlineForText(get(s:result, 0, ''), '^'))
  let s:result = add(s:result, "\n")

  let s:files = s:GetConfigFiles()

  for s:file in s:files
    let s:numberOfMappingsFound = 0

    let s:result = add(s:result, 'File: '.s:file)
    let s:beginAndEndUnderline = s:CreateUnderlineForText(get(s:result, len(s:result) - 1, ''), '=')
    let s:result = add(s:result, s:beginAndEndUnderline)
    let s:result = add(s:result, "\n")

    let s:linesInFile = readfile(s:file)
    let s:lineCount = len(s:linesInFile)
    let s:lineIndex = 0

    while s:lineIndex < s:lineCount
      for s:mapCommand in s:mapCommands

        let s:line = get(s:linesInFile, s:lineIndex, '')

        "add mapping
        if strlen(s:line) > 0 
          if s:line =~ '^'.s:mapCommand 
            "add comment if available
            if s:lineIndex > 0
              let s:previousLine = get(s:linesInFile, s:lineIndex - 1, '')
              if s:previousLine =~ '^"'

                let s:result = add(s:result, s:previousLine)
                
              endif
            endif

            "add mapping line
            let s:result = add(s:result, s:lineIndex.': '.s:line)
            let s:numberOfMappingsFound += 1

            "add empty line
            let s:result = add(s:result, "\n")
          endif
        endif
      endfor

      let s:lineIndex += 1
    endwhile

    let s:result = add(s:result, s:numberOfMappingsFound.' mapping(s) found...')
    let s:result = add(s:result, s:beginAndEndUnderline)
    let s:result = add(s:result, "\n")
  endfor

  return s:result

endfunction

" DisplayByEcho - Display mappings in list by using the :echo command
function! s:DisplayByEcho(mappingsList)

  for s:line in a:mappingsList
    echo s:line
  endfor

endfunction

" DisplayByQuickfix - Display mappings in list by using the :cexpr command
function! s:DisplayByQuickfix(mappingsList)

  cexpr s:mappingsList
  botright copen 30

endfunction

function! s:CreateUnderlineForText(text, underLineCharacter)

  let s:underLine = ''

  let s:textLength = strlen(a:text)
  if s:textLength > 0
    let s:i = 0
    while s:i < s:textLength
      let s:underLine = s:underLine.a:underLineCharacter
      let s:i += 1
    endwhile
  endif

  return s:underLine

endfunction

" DiplayMappings - Function run by the main commands (ViewMaps), displays
" all mappings of a mapping mode in the destination windows or list,
" given by the parameters
function! s:DisplayMappings(mappingMode, destination)

  if count(s:mappingTypes, a:mappingMode) == 1
    let s:mappingsList = s:GetMappingsFor(a:mappingMode)

    if a:destination == 'echo'
      call s:DisplayByEcho(s:mappingsList)
    elseif a:destination == 'quickfix'
      call s:DisplayByQuickfix(s:mappingsList)
    else
      echo 'Destination not supported: '.a:destination
    endif
  else
    echo 'Mapping mode not supported: '.a:mappingMode
  endif

endfunction

"The functionality END ++++++++++++++++++++++++++++++++++++++++++++

" adding example command and mapping
command! -nargs=+ ViewMaps :call s:DisplayMappings(<f-args>)

if !exists('g:viewmaps_map_keys')
    let g:viewmaps_map_keys = 1
endif

if g:viewmaps_map_keys
    nnoremap <silent> <leader>d :ViewMaps n quickfix<CR>
endif

let &cpo = s:save_cpo
unlet s:save_cpo
