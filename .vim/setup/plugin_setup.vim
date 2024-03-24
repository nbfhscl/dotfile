" ---------------------------Plugins----------------------------
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.vim/plugged')
    " general
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'sainnhe/gruvbox-material' " color scheme
    Plug 'tpope/vim-commentary' " gc to comment stuff out
    Plug 'matze/vim-move' " move lines
    Plug 'tpope/vim-surround' " ys/ds/cs/yss/vS to modify surround on objects
    Plug 'tpope/vim-repeat' " repeat plugin commands. vim-surround, etc
    Plug 'sgur/vim-textobj-parameter' " a/i/i2 to select parameter of functions
    Plug 'kana/vim-textobj-user' " create your own text objects
    Plug 'michaeljsmith/vim-indent-object' " ai/aI/ii/iI to select indent object include/uninclude the line above
    "Plug 'johngrib/vim-mac-dictionary' " search word for mac. seems not working anymore
    Plug 'voldikss/vim-translator' " sw to translate the word under cursor
    Plug 'itchyny/lightline.vim' " status bar
"--------------------
    Plug 'airblade/vim-rooter' " changes the working directory to the project root. see configuration in rooter_setup.vim
    Plug 'junegunn/vim-peekaboo' " contents of registers, <c-r> in insert mode
    Plug 'tpope/vim-fugitive' " git integration. see d?
    Plug 'airblade/vim-gitgutter' " shows a git diff in the sign column. ;hs/;hu/;hp stage/undo/preview
"--------------------
    Plug 'christoomey/vim-tmux-navigator' " working with tmux <c-hjkl\>
    Plug 'tpope/vim-eunuch' " sugar for the UNIX shell commands. like :Remove/:Delete/:Chmod/:Mkdir
    Plug 'honza/vim-snippets'
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'puremourning/vimspector'
    Plug 'dgileadi/vscode-java-decompiler'
    " Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
    " Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }
    " a solid language pack for vim
    " Plug 'sheerun/vim-polyglot'
    " Plug 'github/copilot.vim'
    " Plug 'preservim/nerdtree'
    " Plug 'voldikss/vim-floaterm'
    " Plug 'tpope/vim-vinegar'
call plug#end()

let mapleader = ';'

" Basic{{{1

runtime ftplugin/man.vim
" runtime filetype.vim
" runtime ftplugin.vim
" runtime indent.vim
" filetype indent on
" noremap K :Man expand("<cword>")

if exists('loaded_commentary')
    " autocmd FileType apache setlocal commentstring=#\ %s
endif
packadd termdebug
runtime rooter_setup.vim
runtime fzf_setup.vim
runtime coc_setup.vim
runtime vimspector_setup.vim
runtime gruvbox-material_setup.vim
runtime lightline_setup.vim

" the plugin johngrib/vim-mac-dictionary seems not working anymore. see plugin_setup.vim
"if has('mac') 
    "noremap sw :MacDictWordCR
"else 
    noremap sw :TranslateCR
"end

" tmux{{{2

let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <C-w><C-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <C-w><C-j> :TmuxNavigateDown<cr>
nnoremap <silent> <C-w><C-k> :TmuxNavigateUp<cr>
nnoremap <silent> <C-w><C-l> :TmuxNavigateRight<cr>
" nnoremap <silent> {Previous-Mapping} :TmuxNavigatePrevious<cr>

" }}}

" AutoSaveView{{{

" augroup saveview
"     autocmd!
"     autocmd BufWinLeave * silent! mkview
"     " autocmd BufWinEnter * silent if &ft!="txt"| loadview |endif
"     " autocmd BufWinEnter * silent if bufname('')[-8:] isnot# '.txt' | loadview |endif
"     autocmd BufWinEnter * silent! loadview
" augroup END

" }}}

