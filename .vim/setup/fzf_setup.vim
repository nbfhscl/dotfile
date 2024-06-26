" if exists('loaded_fzf_vim')
    let preview_light = {'options': ['--phony', '--preview', 'bat --theme=ansi-light --color=always --style=numbers --line-range=:500 {}', '--info=inline']}

    "[starter]
    nmap sb :Buffers<CR>
    nmap sc :Commands<CR>
    nmap sh :Helptags<CR>
    nmap sm :Maps<CR>
    command! -bang -nargs=? -complete=dir Files
        \ call fzf#vim#files(<q-args>, {'options': ['--preview', 'bat --theme=ansi-light --color=always --style=numbers --line-range=:500 {}', '--info=inline']}, <bang>0)
    nmap sf :Files 
    nmap sv :Files ~/.vim/<CR>
    command! -bang -nargs=? GFiles
        \ call fzf#vim#gitfiles(<q-args>, {'options': ['--preview', 'bat --theme=ansi-light --color=always --style=numbers --line-range=:500 {}', '--info=inline']}, <bang>0)
    nmap sg :GFiles<CR>

    " system command is returning a string with a trailing newline (as it
    " should) and Vim is converting it to a null, which displays ^@
    " strip away the last byte using [:-2]
    autocmd FileType go let b:stdPath = system('go env GOROOT')[:-2]
    function! StdLib()
        execute "Files ".b:stdPath."/src/"
    endfunction
    nmap ss :call StdLib()<CR>

    " command! -bang -nargs=* Rg call fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case -- ".shellescape(<q-args>), 1, fzf#vim#with_preview(), <bang>0)

    " [starter]
    " GGrep
    command! -bang -nargs=* GGrep
    \ call fzf#vim#grep('git grep --line-number '.shellescape(<q-args>), 0,
    \   fzf#vim#with_preview({ 'dir': systemlist('git rev-parse --show-toplevel')[0] }), <bang>0)

    " [starter]
    " fzf complete
    imap <c-x><c-k> <plug>(fzf-complete-word)
    imap <c-x><c-f> <plug>(fzf-complete-path)
    imap <c-x><c-l> <plug>(fzf-complete-line)

    " [starter]
    " searching using :RG <string>
    function! s:RG(fullscreen, ...)
        let l:pat = ''
        let l:dir = expand("%:p:h")
        if a:0 > 0
            " no matter how much args <f-args> contain
            " here a:0 always equal to 1
            " and a:000 is a list of ['arg1 arg2']
            let l:args = split(a:1)
            let l:pat = l:args[0]
            if len(l:args) > 1
                let l:dir = l:args[1]
            endif
            " echom l:args
            " echom l:pat
            " echom l:dir
        endif
        let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
        let initial_command = printf(command_fmt, l:pat.' '.l:dir)
        " {q} if fzf reload placeholder: check man fzf -> /reload
        let reload_command = printf(command_fmt, '{q}'.' '.l:dir)
        let spec = {'options': ['--phony', '--query', l:pat, '--bind', 'change:reload:'.reload_command]}
        call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
    endfunction
    command! -bang -nargs=? -complete=dir RG call s:RG(<bang>0, <f-args>) 


    let $FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!{.git,node_modules}/*" 2> /dev/null'

    let $FZF_DEFAULT_OPTS="
        \--bind 
        \ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down,
        \ctrl-b:page-up,ctrl-f:page-down 
        \"
        " \--preview 'bat --theme=ansi-light --color=always --style=numbers --line-range=:500 {}' 
        " \--preview-window 'right:57%' 
        " \--color=fg:#000000,bg:#ebe9dd,hl:#2181e0 
        " \--color=fg+:#000000,bg+:#9edbd2,hl+:#5fd7ff 
        " \--color=info:#afaf87,prompt:#d7005f,pointer:#af5fff 
        " \--color=marker:#87ff00,spinner:#af5fff,header:#87afaf 
        " \--preview 'bat --color=always --style=numbers --line-range=:500 {}' 


    " [starter]
    " sf/sv/sg to open fzf, <c-r> to insert the selected file name
    " sf/sv/sg to open fzf, <c-s>/<c-t>/<c-v> to open the file
    func! s:insert_file_name(lines)
        let @@ = fnamemodify(a:lines[0], ":p")
        normal! p
    endfunc 
    let g:fzf_action = { 
                \ 'ctrl-r': function('s:insert_file_name'), 
                \ 'ctrl-t': 'tab split', 
                \ 'ctrl-s': 'split', 
                \ 'ctrl-v': 'vsplit',
                \}
    " tab, shift-tab to multiply select and put into quickfix list

" endif

