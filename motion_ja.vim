" vi:set ts=8 sts=2 sw=2 tw=0:
"
" motion_ja.vim - E,W,B,),(�Ǥΰ�ư�����ܸ�����ˤ��뤿��Υ�����ץȡ�
"
" Maintainer: KIHARA Hideto <deton@m1.interq.or.jp>

scriptencoding euc-jp

" Description:
" * ���ܸ�ʸ�Ͼ�Ǥ�E,W,B�Ǥΰ�ư�̤�e,w,b�����礭�����ޤ���
"   ����������ڤ�Ȥߤʤ��ư�ư����褦�ˤ��ޤ���
"   ���ڤ�ʸ����'motion_ja_delim'���ץ����ǻ����ǽ��
"   (����������ư���������礢��)
"
" * )(�Ǥΰ�ư����"��������"��ʸ�Ϥν����Ȥߤʤ��褦�ˤ��ޤ���
"
" ���ץ����:
"    'motion_ja_delim'
"       E,W,B�Ǥΰ�ư����ñ��ζ��ڤ�Ȥߤʤ�ʸ��
"       ��:
"         let motion_ja_delim = "���������֡סء�"
"
"    'plugin_motion_ja_disable'
"       ���Υץ饰������ɤ߹��ߤ����ʤ����˼��Τ褦�����ꤹ�롣
"         let plugin_motion_ja_disable = 1
"
" Note:
"   jvim3����vim6�˰ܹԤ����ݡ�E,W,B�ΰ�ư�̤�e,w,b��Ʊ���ʤΤ����ˤʤäƺ�����
"   ��������ʸ����ޤǤϸ��Ƥ��ʤ��ʰפʤ�Ρ�
"
"   �ʲ���matchit2.vim�����������������ɤ��Ȥ�ʸ����⸫�Ƥ���Τ��ܳ�Ū��
"   http://www.fenix.ne.jp/~G-HAL/soft/nosettle/#vim

if exists('plugin_motion_ja_disable')
  finish
endif

if !exists("motion_ja_delim")
  let motion_ja_delim = "���������������ơǡȡɡʡˡ̡͡ΡϡСѡҡӡԡա֡סء١ڡ�"
endif

nnoremap <silent> E :call <SID>ExecE()<CR>
nnoremap <silent> W :call <SID>ExecW()<CR>
nnoremap <silent> B :call <SID>ExecB()<CR>
nnoremap <silent> ) :call <SID>ForwardS()<CR>
nnoremap <silent> ( :call <SID>BackwardS()<CR>

" TODO: ���ܸ�ʸ�����cE�����Ȥ��ˡ��ѻ����Ѥ��ľ����1ʸ�����Ĥ�
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
    " TODO:"��hoge�Ǥ���"�Τ褦��ʸ�����"��"���W�򤹤��"��"�ξ�ǻߤޤ餺��
    "      ����ʸ�Ϥ���Ƭ�ˤޤǰ�ư���Ƥ��ޤ���
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
    " )�Ǥ�.!?�θ��'")]�����äơ����ڡ���/���Ԥ������Τ�ʸ���Ȥߤʤ��餷��
    execute "silent normal! " . '/\([\.!?][]' . "'" . '")]\=[ \t]\=.*$\)\|\(^$\)\|[��������]/' . "\<CR>"
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
      execute "silent normal! " . '?\([\.!?][]' . "'" . '")]\=[ \t]\=.*$\)\|\(^$\)\|[��������]?' . "\<CR>"
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
