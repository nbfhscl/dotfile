setlocal foldmethod=expr
setlocal foldexpr=GetPotionFold(v:lnum)
function! IndentLevel(lnum)
    return indent(a:lnum) / &shiftwidth
endfunction
function! GetPotionFold(lnum)
	if getline(a:lnum) =~? '\v^\s*$'
		return '0'
	endif
    return IndentLevel(a:lnum) + 1
endfunction


" function! NextNonBlankLine(lnum) 
" 	let numlines = line('$') 
" 	let current = a:lnum + 1
" 	while current <= numlines
" 		if getline(current) =~? '\v\S'
" 			return current
" 		endif
" 		let current += 1
" 	endwhile
" 	return -2
" endfunction

" function! LastNonBlankLine(lnum) 
" 	let current = a:lnum - 1
" 	while current > 0
" 		if getline(current) =~? '\v\S'
" 			return current
" 		endif
" 		let current -= 1
" 	endwhile
" 	return -2
" endfunction


" function! GetPotionFold(lnum)
" 	if getline(a:lnum) =~? '\v^\s*$'
" 		return '-1'
" 	endif
" 	let this_indent = IndentLevel(a:lnum)
" 	let next_indent = IndentLevel(NextNonBlankLine(a:lnum))
"     let last_indent = IndentLevel(LastNonBlankLine(a:lnum))
" 	if next_indent == this_indent 
"         if last_indent <= this.indent
"             return this_indent
"         elseif last_indent > this.indent
"             return '>' . last_indent
"         endif
" 	elseif next_indent < this_indent
" 		return this_indent
" 	elseif next_indent > this_indent
" 		return '>' . next_indent
" 	endif
" endfunction

