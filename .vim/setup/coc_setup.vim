if exists('loaded_coc')
    finish
endif

let g:coc_config_home = '~/.vim/setup'

let mapleader = ';'

let g:coc_global_extensions = []

let g:coc_global_extensions += [
            \'coc-marketplace',
            \'coc-json',
            \'coc-vimlsp',
            \'coc-lists',
            \"coc-snippets",
            \"coc-prettier",
            \]

let g:coc_global_extensions += [
            \'coc-leetcode'
            \]

" markdown
" \'coc-markdownlint',
let g:coc_global_extensions += [
            \'coc-webview',
            \'coc-markdown-preview-enhanced',
            \'coc-texlab',
            \'coc-html'
            \]

" js/ts
let g:coc_global_extensions += [
            \'coc-tsserver'
            \]

"  c
let g:coc_global_extensions += [
            \'coc-clangd',
            \'coc-cmake',
            \]

" ---------------- java -----------------
let g:coc_global_extensions += [
            \'coc-java',
            \'coc-java-lombok',
            \'coc-java-debug',
            \'coc-xml'
            \]
" --------------- go ----------------
"let g:coc_global_extensions += [
"            \ 'coc-go'
"            \]
"
" autocmd FileType java silent! nmap <Leader>dd :AsyncRun mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=12345" -Dspring-boot.run.profiles=local<CR>
" command! -nargs=? DebugJava :AsyncRun mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Dspring.profiles.active=local -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=12345"

"" method 1
function! s:JavaStartDebugCallback(err, adapterPort)
  execute "cexpr! 'Java debug started on port: " . a:adapterPort . "'"
  " call vimspector#LaunchWithSettings({
  "           \ "configuration": "Java Attach",
  "           \ "AdapterPort": a:adapterPort
  "           \ })
  call vimspector#LaunchWithConfigurations({
              \     "Java Attach": {
              \         "adapter": {
              \             "name": "vscode-java",
              \             "port": a:adapterPort
              \         },
              \         "configuration": {
              \             "request": "attach",
              \             "host": "127.0.0.1",
              \             "port": "5050"
              \         },
              \         "breakpoints": {
              \             "exception": {
              \                 "caught": "N",
              \                 "uncaught": "N"
              \             }
              \         }
              \     }
              \ })
endfunction
function JavaStartDebug()
  call CocActionAsync('runCommand', 'vscode.java.startDebugSession', function('s:JavaStartDebugCallback'))
endfunction
command! -nargs=0 JavaAttach :call JavaStartDebug()<CR>
" autocmd FileType java nmap <Leader>dd :call JavaStartDebug()<CR>
autocmd FileType java nnoremap <buffer> ;dd :JavaAttach<CR>

" method 2
" autocmd FileType java nmap <Leader>dd :CocCommand java.debug.vimspector.start<CR>

" -------------------------- mapping --------------------------

" Use `[e` and `]e` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [e <Plug>(coc-diagnostic-prev)
nmap <silent> ]e <Plug>(coc-diagnostic-next)
" Show all diagnostics.
nnoremap <silent><nowait> <Leader>di  :<C-u>CocList diagnostics<cr>

" GoTo code navigation.
" on a function: 1. goto interface; 2. goto inplementation;
" on a variable: 1. goto local/global definiton;
" on a type: 1. goto definition;
nmap <silent> gd <Plug>(coc-definition)
" on a function: 1. do nothing
" on a variable: 1. goto type definition
" on a type: 1. goto type definition;
nmap <silent> gy <Plug>(coc-type-definition)
" on a function: 1. goto implementation
" on a variable: 1. do nothing
" on a type: 1. goto type definiation;
nmap <silent> gi <Plug>(coc-implementation)
" find all references
nmap <silent> gr <Plug>(coc-references)
" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>
" Symbol renaming.
nmap <Leader>rn <plug>(coc-rename)
nmap <Leader>rr <plug>(coc-refactor)

" Applying codeAction to the selected region.
" Example: `<Leader>caap` for current paragraph
xmap <Leader>ca  <Plug>(coc-codeaction-selected)
nmap <Leader>ca  <Plug>(coc-codeaction-line)

" " Remap keys for applying codeAction to the current buffer.
" nmap <Leader>ca  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <Leader>qf  <Plug>(coc-fix-current)

" Run the Code Lens action on the current line.
nmap <Leader>cl  <Plug>(coc-codelens-action)

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Mappings for CoCList
" Find symbol of current document.
nnoremap <silent><nowait> <Leader>co  :<C-u>CocList outline<cr>
" " Manage extensions.
" nnoremap <silent><nowait> <Leader>e  :<C-u>CocList extensions<cr>
" " Show commands.
" nnoremap <silent><nowait> <Leader>cc  :<C-u>CocList commands<cr>
" " Search workspace symbols.
" nnoremap <silent><nowait> <Leader>s  :<C-u>CocList -I symbols<cr>
" " Do default action for next item.
" nnoremap <silent><nowait> <Leader>j  :<C-u>CocNext<CR>
" " Do default action for previous item.
" nnoremap <silent><nowait> <Leader>k  :<C-u>CocPrev<CR>
" " Resume latest coc list.
" nnoremap <silent><nowait> <Leader>p  :<C-u>CocListResume<CR>

" " Use CTRL-S for selections ranges.
" " Requires 'textDocument/selectionRange' support of language server.
" nmap <silent> <C-s> <Plug>(coc-range-select)
" xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')
command! -nargs=0 Prettier :CocCommand prettier.forceFormatDocument

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OI` command for organize imports of the current buffer.
command! -nargs=0 OI   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')
nmap <M-C-O> :<c-u>call     CocActionAsync('runCommand', 'editor.action.organizeImport')<CR>

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Set internal encoding of vim, not needed on neovim, since coc.nvim using some
" unicode characters in the file autoload/float.vim
set encoding=utf-8

" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" " Give more space for displaying messages.
" set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("nvim-0.5.0") || has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
let g:coc_snippet_next = '<tab>'

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
" inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
"                               \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
      " call help in viml and helpdoc
    execute 'h '.expand('<cword>')
  " elseif (coc#rpc#ready())
  elseif (coc#jumpable())
    call CocActionAsync('doHover')
  else
    execute &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
" autocmd CursorHold * silent call CocActionAsync('highlight')

" " Formatting selected code. use autocmd to bind to gq instead
" xmap <Leader>f  <Plug>(coc-format-selected)
" nmap <Leader>f  <Plug>(coc-format-selected)

augroup cocaugroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json,java setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
" set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

if !exists('loaded_coc')
    let g:loaded_coc = 1
    " echo "1"
    " if has('nvim')
    "     call coc#rpc#stop()
    "     echo "nvim found, stop coc.nvim"
    " end
    " echo "3"
end
