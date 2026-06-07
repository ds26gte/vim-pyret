" Vim indent file
" Language:    Pyret
" Maintainer:  Dorai Sitaram, ds26gte.github.io
" Last Change: 2026-06-03

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setl indentexpr=GetPyretIndent(v:lnum)

setl indentkeys=0{,0},0(,0),0[,0],o,O,=\|,=else,=end

if exists("*GetPyretIndent")
  finish
endif

let s:pyretIndentOpeningWords = 'ask\|cases\|check\|data\|for\|fun\|if\|sharing\|switch\|try\|when\|while'

let s:pyretIndentMiddleWords = 'else\|sharing\|where'

let s:pyretIndentClosingWords = 'end'

let s:pyretIndentOpeningBrace = '\(#.*\)\@<!{\s*$'

" let s:pyretIndentClosingBrace = '\(#.*\)\@<!}\s*$'

let s:pyretIndentClosingBrace = '^\s*}\s*$'

let s:pyretIndentClosingStruct = '\(#.*\)\@<!\]\s*$'

let s:pyretIndentOpeningStruct = '\(#.*\)\@<!\[[-[:alpha:]]\+:\s*$'

let s:pyretIndentClosingStruct = '\(#.*\)\@<!\]\s*$'

let s:pyretIndentOpeningFunction = '\(#.*\)\@<!):\s*$'

let s:pyretIndentPipe = '^\s*|'

" optional 'name = ' / 'name := ' / 'var name = ' / 'shadow name = ' prefix,
" so that e.g. 'x = if ...:' is recognized as an opener just like 'if ...:'
let s:pyretIndentAssignPrefix =
      \ '\%(\%(var\|shadow\|rec\)\s\+\)\?\S\+\s*:\?=\s*'

" an opening-word construct that is the value of an assignment, e.g.
" 'x = if ...:' -- such constructs get one extra indent step throughout
let s:pyretIndentAssignOpener =
      \ '^\s*' . s:pyretIndentAssignPrefix . '\(' . s:pyretIndentOpeningWords . '\)\>'

" a word-opener line is only a "true" opener (i.e. its block continues onto
" later lines) if it doesn't already close itself with a trailing 'end' --
" e.g. 'fun log(n): log-base(10, n) end' is a complete one-line expression
let s:pyretIndentWordOpener =
      \ '^\s*\%(' . s:pyretIndentAssignPrefix . '\)\?'
      \. '\(' . s:pyretIndentOpeningWords . '\)\>'
      \. '\%(.*\<end\>\s*\%(#.*\)\?$\)\@!'

let s:pyretIndentOpeners =
      \  s:pyretIndentWordOpener . '\|'
      \. '^\s*\(' . s:pyretIndentMiddleWords . '\)\>\|'
      \. s:pyretIndentOpeningBrace . '\|'
      \. s:pyretIndentOpeningFunction . '\|'
      \. s:pyretIndentOpeningStruct

let s:pyretIndentClosers =
      \  '^\s*\(' . s:pyretIndentClosingWords . '\)\>\|'
      \. '^\s*\(' . s:pyretIndentMiddleWords . '\)\>\|'
      \. s:pyretIndentClosingBrace . '\|'
      \. s:pyretIndentClosingStruct

func! s:PyretBracketContext(lnum)
  " Returns [outermost_opener_line, depth] for the bracket context at the
  " start of lnum, found by repeatedly searching backward for unmatched
  " brackets until none remain.
  let l:depth = 0
  let l:outermost = 0
  let l:save_cursor = getpos('.')
  call cursor(a:lnum, 1)
  while 1
    let l:pos = s:PyretLatestPos(searchpairpos('(', '', ')', 'bWn'),
          \ s:PyretLatestPos(searchpairpos('\[', '', '\]', 'bWn'),
          \                  searchpairpos('{', '', '}', 'bWn')))
    if l:pos[0] == 0
      break
    endif
    let l:depth += 1
    let l:outermost = l:pos[0]
    if l:pos[1] > 1
      call cursor(l:pos[0], l:pos[1] - 1)
    elseif l:pos[0] > 1
      call cursor(l:pos[0] - 1, col([l:pos[0] - 1, '$']))
    else
      break
    endif
  endwhile
  call setpos('.', l:save_cursor)
  return [l:outermost, l:depth]
endfunc

func! s:PyretLatestPos(p1, p2)
  if a:p1[0] > a:p2[0] || (a:p1[0] == a:p2[0] && a:p1[1] > a:p2[1])
    return a:p1
  else
    return a:p2
  endif
endfunc

func! s:PyretFindBlockOpener(cnum)
  " Find the line that opens the block that line `cnum` closes
  " (cnum is expected to be a closing-words line, e.g. 'end')
  let l:pnum = a:cnum - 1
  let l:unmatchedEnds = 0
  while l:pnum > 0
    let l:pLine = getline(l:pnum)
    if l:pLine =~ s:pyretIndentClosers && l:pLine !~ s:pyretIndentOpeners
      let l:unmatchedEnds += 1
    elseif l:pLine =~ s:pyretIndentOpeners && l:pLine !~ s:pyretIndentClosers
      if l:unmatchedEnds <= 0
        return l:pnum
      else
        let l:unmatchedEnds -= 1
      endif
    endif
    let l:pnum -= 1
  endwhile
  return 0
endfunc

func! s:PyretIndentClosingPipe(cnum)
  let l:pnum = a:cnum - 1
  let l:unmatchedEnds = 0
  while l:pnum > 0
    let l:pLine = getline(l:pnum)
    if l:pLine =~ s:pyretIndentPipe
      if l:unmatchedEnds == 0
        return 1
      endif
    elseif l:pLine =~ s:pyretIndentClosers && l:pLine !~ s:pyretIndentOpeners
      let l:unmatchedEnds += 1
    elseif l:pLine =~ s:pyretIndentOpeners && l:pLine !~ s:pyretIndentClosers
      if l:unmatchedEnds <= 0
        return 0
      else
        let l:unmatchedEnds -= 1
      endif
    endif
    let l:pnum -= 1
  endwhile
endfunc

func! GetPyretIndent(cnum)
  let l:pnum = a:cnum - 1

  while l:pnum > 0 && getline(l:pnum) =~ '^\s*$'
    let l:pnum -= 1
  endwhile

  if l:pnum == 0
    return 0
  endif

  let l:suggIndent = indent(l:pnum)

  let l:cLine = getline(a:cnum)
  let l:pLine = getline(l:pnum)

  " Check bracket nesting depth at current line
  let l:bcontext = s:PyretBracketContext(a:cnum)
  if l:bcontext[1] > 0
    return indent(l:bcontext[0]) + l:bcontext[1] * &sw
  endif

  " If previous line was inside brackets we've now exited, adjust base indent
  let l:pbcontext = s:PyretBracketContext(l:pnum)
  if l:pbcontext[1] > 0
    let l:suggIndent = indent(l:pbcontext[0])
  endif

  " If previous line is the 'end' that closes a block whose opener was an
  " assignment (e.g. 'x = if ...'), that block sits one extra indent step
  " deep throughout, including its 'end'; base subsequent lines on the
  " opener's own (non-elevated) indentation instead
  if l:pLine =~ '^\s*\(' . s:pyretIndentClosingWords . '\)\>'
    let l:blockOpener = s:PyretFindBlockOpener(l:pnum)
    if l:blockOpener > 0 && getline(l:blockOpener) =~ s:pyretIndentAssignOpener
      let l:suggIndent = indent(l:blockOpener)
    endif
  endif

  if l:cLine =~ s:pyretIndentClosers
    if l:pLine !~ s:pyretIndentOpeners
      let l:suggIndent -= &sw
      if l:pLine !~ s:pyretIndentPipe && s:PyretIndentClosingPipe(a:cnum)
        let l:suggIndent -= &sw
      endif
    elseif l:pLine =~ s:pyretIndentAssignOpener
      " e.g. 'x = if cond: thenBody' with the then-clause inline --
      " the following 'else'/'end' still get the extra indent step
      let l:suggIndent += &sw
    endif

  elseif l:cLine =~ s:pyretIndentOpeners
    if l:pLine =~ s:pyretIndentOpeners || l:pLine =~ s:pyretIndentPipe
      let l:suggIndent += &sw
      if l:pLine =~ s:pyretIndentAssignOpener
        let l:suggIndent += &sw
      endif
    endif

  elseif l:cLine =~ s:pyretIndentPipe
    if l:pLine =~ s:pyretIndentOpeners
      let l:suggIndent += &sw
      if l:pLine =~ s:pyretIndentAssignOpener
        let l:suggIndent += &sw
      endif
    elseif l:pLine =~ s:pyretIndentPipe
      "stay put
    else
      let l:suggIndent -= &sw
    endif

  else
    if l:pLine =~ s:pyretIndentOpeners || l:pLine =~ s:pyretIndentPipe
      let l:suggIndent += &sw
      if l:pLine =~ s:pyretIndentAssignOpener
        let l:suggIndent += &sw
      endif
    endif
  endif

  return l:suggIndent
endfunc
