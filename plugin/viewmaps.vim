
" Vim global plugin for displaying mappings from your vimrc
" Last Change:  2016 Nov 04	
" Maintainer:	Robert Sarkozi <sarkozi.robert@gmail.com>
" License:	This file is placed in the public domain.
" Version:	0.1.0

if exists("g:loaded_viewmaps")
  finish
endif
let g:loaded_viewmaps = 1

" specifies the orientation of the quickfix window to open
" 0 - horizontal; 1 - vertical
if !exists("g:viewmaps_quickfix_orientation")
  let g:viewmaps_quickfix_orientation = 0
endif

" specifies the height or width of the quickfix window
" default is 25 for the default of 'horizontal'
" it means that many lines in horizontal, or columns in vertical
if !exists("g:viewmaps_quickfix_dimension")
  let g:viewmaps_quickfix_dimension = 25
endif

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

" FilterForEcho - function which formats the list of mappings for
" echoing
function! s:FilterForEcho(mappingMode)

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

    while s:lineIndex <= s:lineCount
      for s:mapCommand in s:mapCommands

        let s:line = get(s:linesInFile, s:lineIndex, '')

        "add mapping
        if strlen(s:line) > 0 
          if s:line =~ '^'.s:mapCommand 
            "add comment if available
            if s:lineIndex > 0
              let s:previousLine = get(s:linesInFile, s:lineIndex - 1, '')
              if s:previousLine =~ '^"'

                let s:result = add(s:result, s:lineIndex.': '.s:previousLine)
                
              else
                "check to see if mapping line contains comment
                let s:revertedLine = join(reverse(split(s:line, '.\zs')), '')
                let s:positionOfComment = match(s:revertedLine, '"')
                if s:positionOfComment > 0
                  let s:revertedComment = split(s:revertedLine, '"')[0]
                  let s:comment = join(reverse(split(s:revertedComment, '.\zs')), '')
                  let s:result = add(s:result, (s:lineIndex + 1).': "'.s:comment)
                  let s:line = split(s:line, '"'.s:comment)[0]
                endif

              endif
            endif

            "add mapping line
            let s:result = add(s:result, (s:lineIndex + 1).': '.s:line)
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

" FilterForQuickFix - function which formats the list of mappings according to
" quickfix format
function! s:FilterForQuickFix(mappingMode)

  "get commands of selected mode
  let s:mapCommands = s:mappingModesMap[a:mappingMode]

  let s:result = []

  let s:files = s:GetConfigFiles()

  for s:file in s:files
    let s:numberOfMappingsFound = 0

    let s:linesInFile = readfile(s:file)
    let s:lineCount = len(s:linesInFile)
    let s:lineIndex = 0 
    "Lines are numbered starting from 0 in a list,
    "but they are numbered starting from 1 in a buffer
    "That is why lineIndex and lineIndex + 1 need to be given to
    "quickfix window items...

    while s:lineIndex < s:lineCount

      let s:line = get(s:linesInFile, s:lineIndex, '')
      if strlen(s:line) > 0 
        for s:mapCommand in s:mapCommands
          if s:line =~ '^'.s:mapCommand 
            "add comment if available
            if s:lineIndex > 0
              let s:previousLineIndex = s:lineIndex - 1
              let s:previousLine = get(s:linesInFile, s:previousLineIndex, '')
              if s:previousLine =~ '^"'
                let s:result = add(s:result, {'filename' : expand(s:file), 'lnum' : s:lineIndex, 'text' : s:previousLine})
              else
                "check to see if mapping line contains comment
                let s:revertedLine = join(reverse(split(s:line, '.\zs')), '')
                let s:positionOfComment = match(s:revertedLine, '"')
                if s:positionOfComment > 0
                  let s:revertedComment = split(s:revertedLine, '"')[0]
                  let s:comment = join(reverse(split(s:revertedComment, '.\zs')), '')
                  let s:result = add(s:result, {'filename' : expand(s:file), 'lnum' : s:lineIndex + 1, 'text' : '"'.s:comment})
                  let s:line = split(s:line, '"'.s:comment)[0]
                endif
              endif
            endif

            "add mapping
            let s:result = add(s:result, {'filename' : expand(s:file), 'lnum' : s:lineIndex + 1, 'text' : s:line})
            let s:numberOfMappingsFound += 1

            "add empty line
            if s:lineIndex + 1< s:lineCount
              let s:result = add(s:result, {'filename' : expand(s:file), 'lnum' : '', 'text' : "\n"})
            endif
          endif
        endfor
      endif

      let s:lineIndex += 1
    endwhile
  endfor

  return s:result

endfunction

" GetMappingsFor - gathers all the mappings, filtered by parameters
function! s:GetMappingsFor(mappingMode, destination)

  if a:destination == 'quickfix'
    let s:result = s:FilterForQuickFix(a:mappingMode)
  elseif a:destination == 'echo'
    let s:result = s:FilterForEcho(a:mappingMode)
  endif

  return s:result

endfunction

" DisplayByEcho - Display mappings in list by using the :echo command
function! s:DisplayByEcho(mappingsList)

  for s:line in a:mappingsList
    echo s:line
  endfor

endfunction

" DisplayByQuickfix - Display mappings in list by using the :cexpr command
function! s:DisplayByQuickfix(mappingMode, mappingsList)

  "get commands of selected mode
  let s:mapCommands = s:mappingModesMap[a:mappingMode]
  let s:title = s:mappingModeNamesMap[a:mappingMode].' mappings: '.join(s:mapCommands, ', ').'. '.s:numberOfMappingsFound.' found...'

  call setqflist([])
  if v:version >= 800
    call setqflist([], 'r', {'title' : s:title})
  endif
  call setqflist(a:mappingsList, 'a')
  let s:orientation = ''
  if g:viewmaps_quickfix_orientation == 1
    let s:orientation = 'vertical '
  endif

  exe s:orientation."botright copen ".g:viewmaps_quickfix_dimension

  if v:version < 800 && exists("w:quickfix_title")
    let w:quickfix_title = s:title
  endif

endfunction

" CreateUnderlineForText - Creates a line as long as text which contains
" only the characters specified in underLineCharacter,
" for underlining text with the new text
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
    let s:mappingsList = s:GetMappingsFor(a:mappingMode, a:destination)

    if a:destination == 'echo'
      call s:DisplayByEcho(s:mappingsList)
    elseif a:destination == 'quickfix'
      call s:DisplayByQuickfix(a:mappingMode, s:mappingsList)
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

let &cpo = s:save_cpo
unlet s:save_cpo
