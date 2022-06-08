if !has('mac')
    if has('termguicolors')
        set termguicolors
    endif
endif

" For dark version.
set background=light

" For light version.
" set background=light

" Set contrast.
" This configuration option should be placed before `colorscheme gruvbox-material`.
" Available values: 'hard', 'medium'(default), 'soft'
let g:gruvbox_material_background = 'hard'
let g:gruvbox_material_palette = 'material'
let g:gruvbox_material_cursor = 'fg0'
let g:gruvbox_material_diagnostic_text_highlight = 1
let g:gruvbox_material_diagnostic_line_highlight = 1
let g:gruvbox_material_diagnostic_virtual_text = 'colored'
let g:lightline = {'colorscheme' : 'gruvbox_material'}

function! s:gruvbox_material_custom() abort
    " Link a highlight group to a predefined highlight group.
    " See `colors/gruvbox-material.vim` for all predefined highlight groups.
    highlight! link CursorLine CustomerCursorLine 
    highlight! link CursorColumn CustomerCursorColumn
    " Initialize the color palette.
    " The first parameter is a valid value for `g:gruvbox_material_background`,
    " and the second parameter is a valid value for `g:gruvbox_material_palette`.
    let l:palette = gruvbox_material#get_palette('soft', 'material', {})
    " Define a highlight group.
    " The first parameter is the name of a highlight group,
    " the second parameter is the foreground color,
    " the third parameter is the background color,
    " the fourth parameter is for UI highlighting which is optional,
    " and the last parameter is for `guisp` which is also optional.
    " See `autoload/gruvbox_material.vim` for the format of `l:palette`.
    call gruvbox_material#highlight('CustomerCursorLine', l:palette.orange, l:palette.none, 'reverse')
    call gruvbox_material#highlight('CustomerCursorColumn', l:palette.orange, l:palette.none, 'reverse')
endfunction

augroup GruvboxMaterialCustom
    autocmd!
    autocmd ColorScheme gruvbox-material call s:gruvbox_material_custom()
augroup END

colorscheme gruvbox-material
