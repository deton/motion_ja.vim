" vi:set ts=8 sts=2 sw=2 tw=0:
"
" motion_ja.vim - E,W,B,),(での移動を日本語向けにするためのスクリプト。
"
" Maintainer: KIHARA Hideto <deton@m1.interq.or.jp>

scriptencoding euc-jp

" Description:
" * 日本語文章上でのE,W,Bでの移動量を、e,w,bよりも大きくします。
"   句読点を区切りとみなして移動するようにします。
"   区切り文字は'motion_ja_delim'オプションで指定可能。
"   (ただし、移動しすぎる場合あり)
"
" * )(での移動時に"。．？！"も文章の終わりとみなすようにします。
"
" オプション:
"    'motion_ja_delim'
"       E,W,Bでの移動時に単語の区切りとみなす文字
"       例:
"         let motion_ja_delim = "、。？！「」『』"
"
"    'plugin_motion_ja_disable'
"       このプラグインを読み込みたくない場合に次のように設定する。
"         let plugin_motion_ja_disable = 1
"
" Note:
"   jvim3からvim6に移行した際、E,W,Bの移動量がe,w,bと同じなのが気になって作成。
"   ただし、文字種までは見ていない簡易なもの。
"
"   以下のmatchit2.vimの方が、漢字コードをもとに文字種も見ているので本格的。
"   http://www.fenix.ne.jp/~G-HAL/soft/nosettle/#vim

if exists('plugin_motion_ja_disable')
  finish
endif

if !exists("motion_ja_delim")
  let motion_ja_delim = "　、。，．？！‘’“”（）〔〕［］｛｝〈〉《》「」『』【】"
endif

nnoremap <silent> E :call <SID>ExecE()<CR>
nnoremap <silent> W :call <SID>ExecW()<CR>
nnoremap <silent> B :call <SID>ExecB()<CR>
nnoremap <silent> ) :call <SID>ForwardS()<CR>
nnoremap <silent> ( :call <SID>BackwardS()<CR>

" TODO: 日本語文字上でcEしたときに、英字に変わる直前の1文字が残る
function! s:ExecE()
  normal! E
  let line = line('.')
  let col = col('.')
  let ch = s:GetCurCh()
  while s:IsMultibyte(ch) && !s:IsDelim(ch)
    let line = line('.')
    let col = col('.')
    normal! E
    let ch = s:GetCurCh()
  endwhile
  if !s:IsDelim(ch)
    call cursor(line, col)
  endif
endfunction

function! s:ExecW()
  if !s:IsMultibyte(s:GetCurCh())
    normal! W
  else
    " TODO:"、hogeです。"のような文字列の"、"上でWをすると"で"の上で止まらずに
    "      次の文章の先頭にまで移動してしまう。
    normal! W
    let ch = s:GetCurCh()
    while s:IsMultibyte(ch) && !s:IsDelim(ch)
      normal! W
      let ch = s:GetCurCh()
    endwhile
    if s:IsDelim(ch)
      normal! w
    endif
  endif
endfunction

function! s:ExecB()
  normal! B
  let line = line('.')
  let col = col('.')
  let ch = s:GetCurCh()
  if s:IsDelim(ch)
    normal! B
    let line = line('.')
    let col = col('.')
    let ch = s:GetCurCh()
  endif
  while s:IsMultibyte(ch) && !s:IsDelim(ch)
    let line = line('.')
    let col = col('.')
    normal! B
    let ch = s:GetCurCh()
  endwhile
  call cursor(line, col)
endfunction

function! s:ForwardS()
  let ws = &wrapscan
  let &wrapscan = 0

  let found = 1
  try
    " )では.!?の後に'")]があって、スペース/改行があるものを文末とみなすらしい
    execute "silent normal! " . '/\([\.!?][]' . "'" . '")]\=[ \t]\=.*$\)\|\(^$\)\|[。．？！]/' . "\<CR>"
  catch /^Vim\%((\a\+)\)\=:E385/	" not found
    let found = 0
  endtry
  if found == 1
    normal! w
  else
    normal! )
  endif

  let &wrapscan = ws
endfunction

function! s:BackwardS()
  let line0 = line('.')
  let col0 = col('.')
  let ws = &wrapscan
  let &wrapscan = 0

  let found = 1
  while found
    try
      execute "silent normal! " . '?\([\.!?][]' . "'" . '")]\=[ \t]\=.*$\)\|\(^$\)\|[。．？！]?' . "\<CR>"
    catch /^Vim\%((\a\+)\)\=:E384/	" not found
      let found = 0
    endtry
    if found == 1
      let linej0 = line('.')
      let colj0 = col('.')
      normal! w
      let linej = line('.')
      let colj = col('.')
      if linej == line0 && colj == col0
	call cursor(linej0, colj0)
      else
	break
      endif
    else
      normal! (
      break
    endif
  endwhile
  let &wrapscan = ws
endfunction

function! s:GetCurCh()
  return matchstr(getline('.'), '.', col('.') - 1)
endfunction

function! s:IsMultibyte(ch)
  let n = char2nr(a:ch)
  if n < 128
    return 0
  else
    return 1
  endif
endfunction

function! s:IsDelim(ch)
  return stridx(g:motion_ja_delim, a:ch) >= 0
endfunction
