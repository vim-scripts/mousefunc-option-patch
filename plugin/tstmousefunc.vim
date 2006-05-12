

" This script tests various aspects of the "mousefunc" option:
"
" - demonstrate having the mouse move tabs in the tabline.
"
" - text hotspots:	Here is mouseover |tag1| and here is |tag2|
"
" - verbose option which shows all mouse info.
"
" - mouse-follow highlighting (set s:show_bullseye)
"
" - associate actions with clicking on statusline words
"

" Change these if you want:
let s:verbose = 0
let s:show_bullseye = 0
let s:test_cmdline = 0


let s:last_mouse_row = 0
let s:last_mouse_col = 0
let s:found_cword = ''
let s:last_hword = ''
let s:last_h_row = 0
let s:last_h_col = 0
let s:start_tab = 0
let s:goto_tab = 0
let s:tab_drag_state = 0
let s:counter = 0

function! Tst_mousefunc( key, buf_row, buf_col, buf_vcol, mouse_row, mouse_col, x, y, area, screen_line )


	" mousefunc is now cleared internally:
	"set mousefunc=

	let buf_row = a:buf_row
	let buf_col = a:buf_col
	let buf_vcol = a:buf_vcol

	call s:Show_mouse_info( a:key, a:buf_row, a:buf_col, a:buf_vcol, a:mouse_row, a:mouse_col, a:x, a:y, a:area, a:screen_line )


	let scrword = matchstr( a:screen_line, '\<\S*\%' . ( a:mouse_col ) . 'c\S*\>' )

	"
	" Drag tabline tabs:
	"
	" This would be better if it had access to the tabline index, but for now,
	" just temporarily move to the selected tab to get it's number.
	"
	if ( a:mouse_row < 1 )
		if a:key == "\<leftdrag>" && s:tab_drag_state == 0
			let s:tab_drag_state = 1
			call feedkeys( "\<leftmouse>", "t" )
			return 0
		elseif a:key == "\<leftdrag>" && s:tab_drag_state == 1
			let s:tab_drag_state = 2
			let s:start_tab = tabpagenr()
			return 0
		elseif a:key == "\<leftdrag>" && s:tab_drag_state == 2
			let s:tab_drag_state = 3
			return 0
		elseif a:key == "\<leftrelease>" && s:tab_drag_state == 3
			let s:tab_drag_state = 4
			call feedkeys( "\<leftmouse>", "t" )
			return 0
		elseif s:tab_drag_state == 4
			let s:goto_tab = tabpagenr()
			if s:goto_tab == s:start_tab
				return 1
			endif
			exe 'tabnext ' . s:start_tab
			exe 'tabmove ' . ( s:goto_tab - 1 )
			let s:tab_drag_state = 0
			return 1
		else
		endif
	else
		let s:tab_drag_state = 0
	endif



	"
	" Do text hotspots:
	"
	if buf_row < 1 | let buf_row = 1 | endif
	if buf_col < 1 | let buf_col = 1 | endif


	let cword = ''
	let hword = ''

	if ( s:last_mouse_row != a:mouse_row
				\ || s:last_mouse_col != a:mouse_col )

		let line = getline( buf_row )
		let col = buf_col
		let row = buf_row


		let cword = matchstr( line, '\<\S*\%' . ( col ) . 'c\S*\>' )

		let hword = matchstr( line, '|\<\S*\%' . ( col ) . 'c\S*\>|' )
		let hword = substitute( hword, '|', '', 'g' )

		let s:found_cword = cword

		if has_key( s:Help_links, hword )
			call Tst_help_open_hot_spot( hword, row, col )
			let s:last_hword = hword
			let s:last_h_row = row
			let s:last_h_col = col
		endif

	endif

	if s:last_hword != '' 
				\ && (
				\		( hword != s:last_hword  && hword != '' )
				\ 		|| buf_row != s:last_h_row
				\		|| buf_col < ( s:last_h_col - 2 )
				\ 		|| buf_col > ( s:last_h_col + 2 )  
				\	)
		" Needs a better column check.
		call Tst_help_close_hot_spot( s:last_hword, s:last_h_row, s:last_h_col )
		let s:last_hword = ''
	endif

	if ( s:counter % 7 ) == 0 && s:show_bullseye
		call s:Bullseye( buf_row, buf_vcol )
	endif




	"
	" Test clicking on an area in the status lines:
	"
	if ( a:area == "IN_STATUS_LINE" && a:key == "\<leftrelease>" )
		if scrword == "_GROW_"
			if winnr() == winnr("$")
				let &cmdheight += 1
			else
				wincmd +
			endif
		elseif scrword == "_SHRINK_"
			if winnr() == winnr("$")
				let &cmdheight -= 1
			else
				wincmd -
			endif
		elseif scrword == "_SPLIT_"
			split
		elseif scrword == "_VSPLIT_"
			vsplit
		elseif scrword == "_QUIT_"
			quit
		endif
		redraw
	endif



	" 
	" Test reading in the command line area:
	"
	if s:test_cmdline
		echo 'Test mouse-over in ->|command|<- line'
		let s:test_cmdline = 0
		if scrword == 'command' && a:area == "IN_STATUS_LINE"
			echo 'Test mouse-over in |<-command->| line'
		endif
	else
		if scrword == 'command' && a:area == "IN_STATUS_LINE"
			let s:test_cmdline = 1
		endif
	endif


	let s:last_mouse_row = a:mouse_row
	let s:last_mouse_col = a:mouse_col
	let s:counter += 1

	return 1

endfunction







function! s:Show_mouse_info( key, buf_row, buf_col, buf_vcol, mouse_row, mouse_col, x, y, area, screen_line )

	if !s:verbose | return | endif

	let buf_row = a:buf_row
	let buf_col = a:buf_col
	let buf_vcol = a:buf_vcol

	if s:verbose && a:key != ''
		echomsg 'gui_send_mouse_event=' . strtrans(a:key, 'l')
	endif

	echo 'key=(' . strtrans(a:key, 'l') . ')=('
				\ . char2nr( a:key[0] )
				\ . ','. char2nr( a:key[1] )
				\ . ','. char2nr( a:key[2] )
				\ . ')'
				\ . ', x=' . a:x
				\ . ', y=' . a:y
				\ . ', buf_row=' . buf_row
				\ . ', buf_col=' . buf_col
				\ . ', buf_vcol=' . buf_vcol
				\ . ', line(.),col(.)=' . line(".") . ',' . col(".")
				\ . ', mouse_row=' . a:mouse_row
				\ . ', mouse_row=' . a:mouse_col
				\ . ', cword=' . s:found_cword
				\ . ( a:key == '' ? '' : ', key=' . strtrans(a:key, 'l')
				\ . ', 0=' . char2nr( a:key[0] )
				\ . ', 1=' . char2nr( a:key[1] )
				\ . ', 2=' . char2nr( a:key[2] )
				\   )
				\ . ', area=' . a:area

				" too much:
				"\ . ( s:last_screen_line == a:screen_line ? '' : ', line=' . a:screen_line )
				" 
				" Always empty:
				" \ . ', mousefunc=' . &mousefunc
endfunction




"Here is |tag1| and here is |tag2|
"

let s:Help_links = {
			\ 'tag1' : ' mouse over tag 1',
			\ 'tag2' : ' mouse over tag 2',
			\ }

function! Tst_help_open_hot_spot( key, line, col )
	hi clear Tst_hot_info
	hi link Tst_hot_info DiffChange

	if !has_key( s:Help_links, a:key )
		return
	endif

	let line = getline( a:line )
	let line = substitute( line, '|' . a:key . '|', '|' . s:Help_links[ a:key ] . '|', 'g' )
	call setline( a:line, line )

	syn clear Tst_hot_info
	let s = '2match Tst_hot_info /' . s:Help_links[ a:key ] . '/'
	exe s
	redraw
endfunction



function! Tst_help_close_hot_spot( key, line, col )

	let line = getline( a:line )
	let line = substitute( line,  '|' . s:Help_links[ a:key ] . '|', '|' . a:key . '|', 'g' )
	call setline( a:line, line )
	2match
	redraw

endfunction




let s:bullseye_state = 0
hi link click_bullseye1 diffadd " statusline " error
hi link click_bullseye2 diffchange " statusline " error

function! s:Bullseye( line, virtcol )

	let l:line = a:line
	let l:virtcol = a:virtcol

		silent! exe '2match Visual /'
					\ . '\%>' . ( l:line - 4 ) . 'l'
					\ . '\%<' . ( l:line + 4 ) . 'l'
					\ . '\%>' . ( l:virtcol - 7 ) . 'v'
					\ . '\%<' . ( l:virtcol + 7 ) . 'v'
					\ . '/'

	if s:bullseye_state == 0
		let s:bullseye_state = 1
		silent! exe 'match click_bullseye1 /'
					\ . '\%>' . ( l:line - 4 ) . 'l'
					\ . '\%<' . ( l:line + 4 ) . 'l'
					\ . '\%>' . ( l:virtcol - 7 ) . 'v'
					\ . '\%<' . ( l:virtcol + 7 ) . 'v'
					\ . '/'
	elseif s:bullseye_state == 1
		let s:bullseye_state = 2
		silent! exe 'match click_bullseye2 /'
					\ . '\%>' . ( l:line - 3 ) . 'l'
					\ . '\%<' . ( l:line + 3 ) . 'l'
					\ . '\%>' . ( l:virtcol  - 6 ) . 'v'
					\ . '\%<' . ( l:virtcol  + 6 ) . 'v'
					\ . '/'
	elseif s:bullseye_state == 2
		"let s:bullseye_state = -1
		let s:bullseye_state = 0
		silent! exe 'match Error /'
					\ . '\%>' . ( l:line - 2 ) . 'l'
					\ . '\%<' . ( l:line + 2 ) . 'l'
					\ . '\%>' . ( l:virtcol - 4 ) . 'v'
					\ . '\%<' . ( l:virtcol + 4 ) . 'v'
					\ . '/'

					"\ . '\%' . ( line(".")  ) . 'l'
					"\ . '\%' . ( virtcol(".") ) . 'v'
	else
		match		" clear
	endif

	redraw
endfunction







if &statusline =~ '_GROW_'
	let &statusline = substitute( &statusline, '\[__*GROW.*', '', '' )
endif
let &statusline .= " [_GROW_] [_SHRINK_] [_SPLIT_] [_VSPLIT_] [_QUIT_]"


set mousefunc=Tst_mousefunc


