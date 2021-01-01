" The idea is to keep this somewhat simple so I can continue to use vim as a
" runs-everywhere in-terminal editor on other (unconfigured) computers
" without my muscle memory being totally thrown off
" http://vim.wikia.com/wiki/Example_vimrc
" http://dougblack.io/words/a-good-vimrc.html
" https://github.com/tpope/vim-sensible

set nocompatible
filetype plugin indent on
syntax enable

set hidden

set backspace=indent,eol,start

" MAJOR QUALITY OF LIFE IMPROVEMENTS
" use kj as an alternative to esc (in interactive mode)
inoremap kj <Esc>
" use semicolon as an alternative to colon (in normal mode)
nnoremap ; :

" INDENT
set autoindent
set shiftwidth=4
set tabstop=4
set shiftround
set expandtab

set nostartofline

" UI
set showcmd
set wildmenu
set ruler
set showmatch
set number
set lazyredraw
set ttyfast
set mouse=a
set scrolloff=1

set foldenable
set foldlevel=200
set foldmethod=indent

vnoremap <C-C> "+y
vnoremap <C-P> "+gP

" SEARCH
set ignorecase
set smartcase
set incsearch
set hlsearch

set history=50
set directory=~/.vim/.swp//
set nobackup

" when editing a file, jump to last known cursor position (except sometimes)
autocmd BufReadPost *
\ if line("'\"") > 1 && line("'\"") <= line("$") |
\   exe "normal! g`\"" |
\ endif

let g:syntastic_python_checkers = ['flake8']

" PLUGINS
call plug#begin('~/.vim/plugged')
Plug 'airblade/vim-gitgutter'
Plug 'vim-syntastic/syntastic'
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline'
Plug 'preservim/nerdtree'
call plug#end()
