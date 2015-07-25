set nocompatible                " Be iMproved, required
filetype off                    " Required

" Vundle
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'

" Common Plugins
Plugin 'airblade/vim-gitgutter'
Plugin 'bling/vim-airline'
Plugin 'ervandew/supertab'
Plugin 'godlygeek/tabular'
Plugin 'justinmk/vim-sneak'
Plugin 'kien/ctrlp.vim'
Plugin 'lukerandall/haskellmode-vim'
Plugin 'majutsushi/tagbar'
Plugin 'marijnh/tern_for_vim'
Plugin 'mattn/gist-vim'
Plugin 'mattn/webapi-vim'
Plugin 'mbbill/undotree'
Plugin 'octol/vim-cpp-enhanced-highlight'
Plugin 'plasticboy/vim-markdown'
Plugin 'scrooloose/nerdcommenter'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'tpope/vim-fireplace'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-sensible'
Plugin 'tpope/vim-surround'
Plugin 'vim-latex/vim-latex'

" Unix Plugins
if has("unix")
    if has("python")
        Plugin 'valloric/youcompleteme'
    endif
endif

" Color Plugins
Plugin 'altercation/vim-colors-solarized'
Plugin 'tomasr/molokai'

call vundle#end()               " Required
filetype plugin indent on       " Required

set hidden                      " Hide buffers
set showcmd                     " Show current command
set encoding=utf-8              " UTF-8 encoding
set ruler                       " Show ruler
set autoread                    " Auto reload

" Temp Files
set nobackup                    " No backup file
set noswapfile                  " No swap file

" Undo
set undodir=~/.vim/undo       
set undofile
set undolevels = 1000           " Maximum # changes
set undoreload = 10000          " Maximum # lines to save for undo on a buffer reload

" Line Numbers
set rnu                         " Relative line numbers
set nu                          " Line numbers

" Scrolling
set scrolloff=5                 " Keep at least 5 lines above/below
set sidescrolloff=5             " Keep at least 5 lines left/right

" Searching
set incsearch                   " Incremental search
set hlsearch                    " Highlight matches
set ignorecase                  " Case-insensitive search
set smartcase                   " Unless search contains uppercase letter
set showmatch                   " Show matching bracket

" Indentation
set smartindent                 " Inserts new level of indentation
set autoindent                  " Copy indentation from previous line
set tabstop=4                   " Columns a tab counts for
set softtabstop=4               " Columns a tab inserts in insert mode
set shiftwidth=4                " Columns inserted with the reindent operations
set shiftround                  " Always indent by multiple of shiftwidth
set expandtab                   " Always use spaces instead of tabs

" Spaces
set nojoinspaces                " Only one space

" Mouse
set mousehide                   " Hide mouse when typing
set mouse=nicr                  " No visual selection from using mouse

" Colors & Syntax
syntax enable                   " Enable syntax highlighting
set background=dark             " Set background color
colorscheme solarized           " Set color scheme
highlight clear SignColumn      " Sing column same background as line numbers

" Wrapping
set nowrap                      " No wrapping
set linebreak                   " Only wrap at certain characters
set textwidth=0                 " Turn off physical line wrapping
set wrapmargin=0                " Turn off physical line wrapping
set nolist                      " Disable line breaks

" Completion Menu
set completeopt=longest,menuone

" Spell Checking
set spelllang=en_us             " Default language
set complete+=kspell            " Word completion
nnoremap <silent> <F2> :set spell!<CR>

autocmd BufRead,BufNewFile *.md  setlocal spell
autocmd BufRead,BufNewFile *.tex setlocal spell
autocmd FileType gitcommit setlocal spell

" GUI
if has("gui_running")
    set lines=999 columns=999
    let g:solarized_termtrans=1
    let g:solarized_termcolors=256
    if has("gui_gtk2")
        set guifont=Source\ Code\ Pro\ for\ Powerline:h12,Source\ Code\ Pro:h12
    elseif has("gui_macvim")
        set guifont=Source\ Code\ Pro\ for\ Powerline:h14,Source\ Code\ Pro:h14
    elseif has("gui_win32")
        set guifont=Source\ Code\ Pro\ for\ Powerline:h12,Source\ Code\ Pro:h12
    endif
endif

" Disable Bells
set noeb vb t_vb=
au GUIEnter * set vb t_vb=

" Disable Arrow Keys
nmap  <Up>     <NOP>
nmap  <Down>   <NOP>
nmap  <Left>   <NOP>
nmap  <Right>  <NOP>

" Shortcuts
vmap Q gq
nmap Q gqap

" Buffers
map <silent> <C-Tab> :bnext<CR>
map <silent> <S-Tab> :bprevious<CR>
map <silent> <F4>    :b#<bar>bd#<CR>

" Windows
nmap <silent> <A-Up>    :wincmd k<CR>
nmap <silent> <A-Down>  :wincmd j<CR>
nmap <silent> <A-Left>  :wincmd h<CR>
nmap <silent> <A-Right> :wincmd l<CR>
nnoremap <silent> <F3>  <C-w>q

" Copy/Paste
vmap <C-c> "+yi
vmap <C-x> "+c
vmap <C-v> c<ESC>"+p
imap <C-v> <ESC>"+pa

" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 1
let g:syntastic_cpp_checkers = ['cppcheck']

" CTRL-P
let g:ctrlp_root_markers = ['Makefile']
let g:ctrlp_use_caching = 1

" Ctags
set tags=./tags,tags;$HOME

" Undotree
nnoremap <F5> :UndotreeToggle<CR>

" Tagbar
nnoremap <F8> :TagbarToggle<CR>
let g:tagbar_right = 1
let g:tagbar_width = 35
let g:tagbar_autofocus = 1
autocmd FileType * nested :call tagbar#autoopen(0)

" NERDTree
let NERDTreeWinPos = "left"
let NERDTreeWinSize = 35
let NERDTreeIgnore = ['\.job$', '^CVS$', '\.orig', '\~$']
let g:NERDTreeDirArrows = 0
let g:NERDTreeStatusline = "%f"
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
nnoremap <F10> :NERDTreeToggle<CR>
nnoremap <F9> :NERDTreeFind<CR>

" You Complete Me
let g:ycm_global_ycm_extra_conf = '~/.vim/.ycm_extra_conf.py'
let g:ycm_server_keep_logfiles = 1
let g:ycm_min_num_of_chars_for_completion = 2
let g:ycm_min_num_identifier_candidate_chars = 0
let g:ycm_auto_trigger = 1

" Airline
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#fnamemod = ':t'

" LaTeX
let g:Tex_DefaultTargetFormat = 'pdf'
let g:Tex_MultipleCompileFormats='pdf, aux'
let g:Imap_FreezeImap=1         " Disable mappings
let Tex_FoldedSections=''       " Disable folding sections
let Tex_FoldedEnvironments=''   " Disable folding environments
let Tex_FoldedMisc=''           " Disable folding miscellaneous
if has("win32")
    let g:Tex_ViewRule_pdf = 'SumatraPDF -reuse-instance'
endif

" Markdown
let g:vim_markdown_folding_disabled = 1

" Gist
let g:gist_post_private = 1     " Private by default
let g:gist_detect_filetype = 1  " Detect type from the file name
let g:gist_update_on_write = 2  " Only :w! updates a gist

" Remove Trailing Whitespace
autocmd BufWritePre * :%s/\s\+$//e

" Haskellmode
let g:haddock_browser="chrome"
if has("win32")
endif

" Watch $MYVIMRC
augroup reload_myvimrc
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END
