" ---------------------------Plugins----------------------------
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  " autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.vim/plugged')
    Plug 'sainnhe/gruvbox-material'
    Plug 'itchyny/lightline.vim'
    Plug 'tpope/vim-commentary'
    Plug 'michaeljsmith/vim-indent-object'
    Plug 'matze/vim-move'
    Plug 'tpope/vim-repeat'
    Plug 'tpope/vim-surround'
    Plug 'sgur/vim-textobj-parameter'
    Plug 'kana/vim-textobj-user'
    Plug 'airblade/vim-rooter'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'tpope/vim-fugitive'
    Plug 'johngrib/vim-mac-dictionary'
    Plug 'voldikss/vim-translator'
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'puremourning/vimspector'
    Plug 'airblade/vim-gitgutter'
    Plug 'christoomey/vim-tmux-navigator'
    Plug 'honza/vim-snippets'
    Plug 'tpope/vim-eunuch'
    Plug 'junegunn/vim-peekaboo'
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
"
if has('mac') 
    noremap sw :MacDictWord<CR>
else 
    noremap sw :Translate<CR>
end

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

