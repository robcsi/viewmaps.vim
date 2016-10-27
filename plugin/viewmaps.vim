
" Vim global plugin for displaying mappings from your vimrc
" Last Change:	2016 Oct. 24
" Maintainer:	Robert sarkozi <sarkozi.robert@gmail.com>
" License:	This file is placed in the public domain.
" Version:	0.1.0

if exists("g:loaded_viewmaps")
  finish
endif
let g:loaded_viewmaps = 1

let s:save_cpo = &cpo
set cpo&vim

"if !exists("s:did_load")

  "if !exists(":ViewMaps")
    "let s:currentFile = expand("$MYVIMRC")
    "echo s:currentFile
    "command -nargs=0  ViewMaps  :call s:ReadFile(s:currentFile)
  "endif

  "let s:did_load = 1
  ""exe 'au FuncUndefined s:ReadFile* source ' . expand('<sfile>')
  "finish
"endif

"The functionality BEGIN ++++++++++++++++++++++++++++++++++++++++++

let s:mappingTypes = ['i', 'n', 'v', 'c', 's', 'x', 'o', '!', 'l']
echo s:mappingTypes

function! s:ReadFile(filePath)
  for line in readfile(a:filePath, '', 10)
    if line =~ 'source' | echo line | endif
    echo 'robcsi'
  endfor
endfunction

"The functionality END ++++++++++++++++++++++++++++++++++++++++++++

"the new way
if !exists('g:viewmaps_map_keys')
    let g:viewmaps_map_keys = 1
endif

if g:viewmaps_map_keys
    nnoremap <leader>d :call <sid>ReadFile(expand("$MYVIMRC"))<CR>
endif

"the old way (help)
if !hasmapto('<Plug>ViewmapsReadfile')
  map <unique> <Leader>M  <Plug>ViewmapsReadfile
endif
noremap <unique> <script> <Plug>ViewmapsReadfile  <SID>ReadFile

noremap <Plug>ReadFile  :call <SID>Readfile(s:currentFile)<CR>

if !exists(":ViewMaps")
  let s:currentFile = expand("$MYVIMRC")
  echo s:currentFile
  command! -nargs=0 ViewMaps :call s:ReadFile(s:currentFile)
endif

let &cpo = s:save_cpo
unlet s:save_cpo
