let VIMDIR=expand($DOTFILES_VIM_PATH) . "/vimdir"

set runtimepath^=$DOTFILES_VIM_PATH/vimdir

" Automate plug.vim installation
if empty(glob(VIMDIR . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.VIMDIR.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

" install plugins
call plug#begin(VIMDIR . '/plugged')

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

" colorscheme koehler
colorscheme onedark
set cursorline
