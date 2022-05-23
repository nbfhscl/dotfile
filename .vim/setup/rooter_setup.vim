" let g:rooter_manual_only = 1
" nnoremap <leader>cd :Rooter<CR>
" let g:rooter_cd_cmd = 'lcd'
" let g:rooter_patterns = ['!.git']
let g:rooter_patterns = []
let g:rooter_patterns += [ 'pom.xml', 'CMakeLists.txt', 'Makefile' ]
let g:rooter_change_directory_for_non_project_files = 'current'
