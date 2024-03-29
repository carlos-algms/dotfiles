" https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
" The installation is being done only once now in the install script


" load plugins
call plug#begin()

Plug 'sheerun/vim-polyglot'
Plug 'itchyny/lightline.vim'
Plug 'chr4/nginx.vim', { 'for': 'nginx' }
" Plug 'nanotech/jellybeans.vim'
Plug 'joshdick/onedark.vim'
Plug 'terryma/vim-multiple-cursors'

call plug#end()

syntax on

set tabstop=4 shiftwidth=4 softtabstop=4
set expandtab
set list listchars=tab:\|-,trail:~,extends:>,precedes:<
set smarttab
set smartindent
set wrap
set bs=indent,eol,start
set nocompatible
set foldmethod=syntax
set foldlevelstart=99
set scrolloff=50
set ignorecase


" map <C-W> :qa!<Enter>

set laststatus=2
set statusline=%f%m%r%h%w\ (%{&ff}){%Y}\ [%l,%v]%=[%p%%,%L\ lines]

" Highlight current cursor line
set cul
hi CursorLine term=bold cterm=bold

" Use all utf-8 for encoding a file.
scriptencoding utf-8
set fileencodings=utf-8
set encoding=utf-8

" set colorcolumn=101
" hi ColorColumn ctermbg=236 guibg=#444444

nmap <S-F5> :tabn<CR>
nmap <S-F6> :tabp<CR>
nmap <F5> <C-w>W
nmap <F6> <C-w>w

" enable theme for lightline
let g:lightline = {
  \ 'colorscheme': 'onedark',
  \ }

set cursorline

"  if ! empty(glob('~/.vim/plugged/onedark.vim'))
" colorscheme koehler
colorscheme onedark
"  endif
