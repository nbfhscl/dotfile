if has('nvim')
    " runtime! init.lua
    " lua require('')

    runtime nvim_setup.lua

    " different from vim version
    command! Tt :tabe | terminal
    command! Vt :rightb vsplit | terminal
    command! St :bo split | terminal
    " fix window width and height, set minimal win height
    au TermOpen * setlocal winfixwidth winfixheight
    au TermOpen * set winheight=2 winminheight=2
    " terminal vi mode not work if esc bind to tnoremap
    " tnoremap <Esc> <C-\><C-n>
    " tnoremap <expr> <C-R> '<C-\><C-N>"'.nr2char(getchar()).'pi'
    tnoremap <C-w>h <C-\><C-N><C-w>h
    tnoremap <C-w>j <C-\><C-N><C-w>j
    tnoremap <C-w>k <C-\><C-N><C-w>k
    tnoremap <C-w>l <C-\><C-N><C-w>l
    tnoremap gt <C-\><C-N>gt
    tnoremap gT <C-\><C-N>gT
    " <C-w> in insert mode will make <C-w>(delete word before cursor) latency
    " inoremap <C-w><C-h> <C-\><C-N><C-w>h
    " inoremap <C-w><C-j> <C-\><C-N><C-w>j
    " inoremap <C-w><C-k> <C-\><C-N><C-w>k
    " inoremap <C-w><C-l> <C-\><C-N><C-w>l

    " move
    " packadd hop.nvim
    " lua require'hop'.setup()
    " noremap sk :HopChar2<CR>
    " noremap sj :HopWord<CR>

    ""language

    "lua require('lsp')
    "augroup packer_user_config
    "    autocmd!
    "    autocmd BufWritePost lsp.lua source <afile> | PackerCompile
    "augroup end

    "" ui
    " packadd nvim-colorizer.lua
    " set termguicolors
    " lua require'colorizer'.setup()


    " call plug#begin('~/.vim/plugged')
    " Plug 'nvim-lua/plenary.nvim'
    " Plug 'nvim-telescope/telescope.nvim'
    " Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

    " ui
    " Plug 'norcalli/nvim-colorizer.lua'
    " call plug#end()

    " if exists('loaded_telescope')
    "     lua require('telescope').setup{}
    "     lua require('telescope').load_extension('fzf')
    " endif

    " Using Lua functions
    " nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
    " nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
    " nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
    " nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>


    "if exists('g:vscode')
    "    autocmd InsertLeave * :silent :!E://Syno im-select.exe 1033
    ""    autocmd InsertEnter * :silent :!C:\\tools\\neovim\\im-select.exe 2052
    "else
    "endif
endif

