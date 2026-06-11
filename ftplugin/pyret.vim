" Vim filetype plugin file
" Language:    Pyret
" Maintainer:  Dorai Sitaram, ds26gte.github.io
" Last Change: 2026-06-11

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

setl cms=#\ %s
setl isk+=-

let b:match_words =
      \ '\<\(\(^\s*\)\@<=block\|cases\|check\|data\(\s\+[^\:]\+\:\)\@=\|for\|fun\|\(else\s\+\)\@<!if\|lam\|method\|provide\|try\|when\)\>' ..
      \ ':\<\(else\(\s\+if\)\?\|where\)\>' ..
      \ ':\<end\>,' ..
      \ '#|:|#'
