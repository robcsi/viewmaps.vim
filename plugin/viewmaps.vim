
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

"The functionality BEGIN ++++++++++++++++++++++++++++++++++++++++++
function! s:ReadFile(filePath)
  let currentFile = expand("$MYVIMRC")
  for line in readfile(currentFile, '', 10)
    if line =~ 'source' | echo line | endif
  endfor
  echo currentFile
endfunction
"The functionality END ++++++++++++++++++++++++++++++++++++++++++++

"the new way
if !exists('g:viewmaps_map_keys')
    let g:viewmaps_map_keys = 1
endif

if g:viewmaps_map_keys
    nnoremap <leader>d :call <sid>ReadFile()<CR>
endif

"the old way (help)

if !hasmapto('<Plug>ViewmapsReadfile')
  map <unique> <Leader>M  <Plug>ViewmapsReadfile
endif
noremap <unique> <script> <Plug>ViewmapsReadfile  <SID>ReadFile

noremap <Plug>ReadFile  :call <SID>Readfile()<CR>

if !exists(":ViewMaps")
  command -nargs=0  ViewMaps  :call s:ReadFile("afsf")
endif

let &cpo = s:save_cpo
unlet s:save_cpo
