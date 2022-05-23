call plug#begin('~/.vim/plugged')
    Plug 'ycm-core/YouCompleteMe', { 'do': './install.py' }
call plug#end()
nnoremap <leader>rr :YcmCompleter RefactorRename 
nnoremap gh :YcmCompleter GetDoc<CR>
"nmap <leader>yfw <Plug>(YCMFindSymbolInWorkspace)
"nmap <leader>yfd <Plug>(YCMFindSymbolInDocument)
"nnoremap <leader>yc :YcmForceCompileAndDiagnostics<CR>
"nnoremap <leader>yd :YcmDiags<CR>
"nnoremap <leader>gr :YcmCompleter GoToReferences<CR>
" nnoremap <C-b> :YcmCompleter GoToImprecise<CR>
"nnoremap <C-b> :YcmCompleter GoTo<CR>
"nnoremap <leader>go :YcmCompleter GoToDocumentOutline<CR>
" not rename .h?
" not work?
"nnoremap <leader>gf :YcmCompleter FixIt<CR>
"nnoremap <leader>go :YcmCompleter GetType<CR>
"nnoremap <leader>go :YcmCompleter GetTypeImprecise<CR>
"nnoremap gh :YcmCompleter GetDocImprecise<CR>
"nnoremap <leader>gi :YcmCompleter GoToImplementation<CR>
"nnoremap <leader>ysd :YcmShowDetailedDiagnostic<CR>
"nnoremap <leader>gd :YcmCompleter GoToDefinition<CR>
"nnoremap <leader>gi :YcmCompleter GoToDeclaration<CR>
"nnoremap <C-b> :YcmCompleter GoTo<CR>
"nnoremap <C-m> :YcmCompleter GoToImprecise<CR> # can not map <C-m>, it equals <CR>
":YcmToggleLogs
