if exists('loaded_move')                 
    if has('mac')
        " this is not required when enable use option as meta key
        " terminal-->preference-->profiles-->keybords-->use option as meta key
        " nnoremap ˙  <<
        " nmap ∆ <Plug>MoveLineDown
        " nmap ˚ <Plug>MoveLineUp
        " nnoremap ¬ >>
        " vnoremap ˙ <gv
        " vmap ∆ <Plug>MoveBlockDown
        " vmap ˚ <Plug>MoveBlockUp
        " vnoremap ¬ >gv
    elseif has('nvim')
    else
        silent! execute 'vunmap' '<M-j>'
        silent! execute 'vunmap' '<M-k>'
        silent! execute 'vunmap' '<M-h>'
        silent! execute 'vunmap' '<M-l>'
        silent! execute 'nunmap' '<M-j>'
        silent! execute 'nunmap' '<M-k>'
        silent! execute 'nunmap' '<M-h>'
        silent! execute 'nunmap' '<M-l>'
        " for terms that send Alt as Escape esequenc     
        " see http://vim.wikia.com/wiki/Mapping_fast_keycodes_in_terminal_Vim
        set ttimeoutlen=10
        set <F13>=h
        set <F14>=j
        set <F15>=k
        set <F16>=l
        nnoremap <F13> <<
        nmap <F14> <Plug>MoveLineDown
        nmap <F15> <Plug>MoveLineUp
        nnoremap <F16> >>
        vnoremap <F13> <gv
        vmap <F14> <Plug>MoveBlockDown
        vmap <F15> <Plug>MoveBlockUp
        vnoremap <F16> >gv
    endif
end
