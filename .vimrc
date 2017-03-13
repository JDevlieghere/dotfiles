set nocompatible

" ---------------------------------------------------------------------------- "
" Plug                                                                         "
" ---------------------------------------------------------------------------- "

call plug#begin('~/.vim/plugged')

" Color Schemes
Plug 'altercation/vim-colors-solarized'
Plug 'nanotech/jellybeans.vim'
Plug 'chriskempson/base16-vim'

" Plug-ins
Plug 'Shougo/vimproc.vim', { 'do': 'make' }
Plug 'ciaranm/detectindent'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'majutsushi/tagbar'
Plug 'mhinz/vim-signify'
Plug 'moll/vim-bbye'
Plug 'rhysd/vim-clang-format'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/syntastic'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" On-Demand Plug-ins
Plug 'chiel92/vim-autoformat', { 'on': 'Autoformat' }
Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' }
Plug 'octol/vim-cpp-enhanced-highlight', { 'for': 'cpp' }
Plug 'rhysd/vim-grammarous', { 'on': 'GrammarousCheck' }
Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeFind', 'NERDTreeToggle'] }
Plug 'vim-scripts/DoxygenToolkit.vim', { 'for': 'cpp' }

" Golang
Plug 'fatih/vim-go', { 'for': 'go' }

" Haskell
Plug 'Twinside/vim-hoogle', { 'for': 'haskell' }
Plug 'eagletmt/ghcmod-vim', { 'for': 'haskell' }
Plug 'eagletmt/neco-ghc', { 'for': 'haskell' }
Plug 'mpickering/hlint-refactor-vim', { 'for': 'haskell' }

" LLVM
Plug 'jdevlieghere/llvm.vim', { 'for': 'llvm' }

" Mardown
Plug 'godlygeek/tabular' | Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }

" Rust
Plug 'racer-rust/vim-racer', { 'for': 'rust' }
Plug 'rust-lang/rust.vim', { 'for': 'rust' }

" YouCompleteMe
if has("python")
    Plug 'valloric/youcompleteme', { 'do': './install.py --clang-completer --gocode-completer --tern-completer --racer-completer' }
endif

call plug#end()

" ---------------------------------------------------------------------------- "
" Vanilla Vim                                                                  "
" ---------------------------------------------------------------------------- "

" Colors & Syntax
syntax enable                   " Enable syntax highlighting
set background=dark             " Dark background color

" Color Scheme
colorscheme solarized           " Solarized color scheme
highlight clear SignColumn      " Sing column same background as line numbers

" Essentials
filetype plugin indent on       " Enable file type support
set encoding=utf-8              " UTF-8 encoding
set binary                      " Enable binary support
set hidden                      " Hide buffers
set showcmd                     " Show current command
set showmode                    " Show current mode
set autoread                    " Auto reload
set ttyfast                     " Fast terminal
set ruler                       " Show ruler
set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%)
set nofoldenable                " disable folding
set laststatus=2                " Alwasy display statusline

" Crypto
set cm=blowfish

" Temp Files
set nobackup                    " No backup file
set noswapfile                  " No swap file

" Line Numbers
set nu                          " Show line numbers
"set rnu                        " Relative line numbers

" Rulers
set colorcolumn=80,120          " Show ruler columns

" Cursor Line
"set cursorline

" Scrolling
set scrolloff=3                 " Keep at least 3 lines above/below
set sidescrolloff=3             " Keep at least 3 lines left/right

" Searching
set incsearch                   " Incremental search
set hlsearch                    " Highlight matches
set ignorecase                  " Case-insensitive search
set smartcase                   " Unless search contains uppercase letter
set showmatch                   " Show matching bracket
vnoremap // y/<C-R>"<CR>        " Search for visual selection

" Indentation
set smarttab                    " Better tabs
set smartindent                 " Inserts new level of indentation
set autoindent                  " Copy indentation from previous line
set tabstop=2                   " Columns a tab counts for
set softtabstop=2               " Columns a tab inserts in insert mode
set shiftwidth=2                " Columns inserted with the reindent operations
set shiftround                  " Always indent by multiple of shiftwidth
set expandtab                   " Always use spaces instead of tabs

" Key sequence timeout
set ttimeout                    " Enable time out
set ttimeoutlen=100             " Set timeout time to 100 ms

" Backspace
set backspace=indent,eol,start  " Delete over line breaks

" Mouse
set mousehide                   " Hide mouse when typing
set mouse=nicr                  " Disable mouse

" Typos
cnoreabbrev W w
cnoreabbrev Q q
command! Qa :qa!

" Italics
highlight Comment cterm=italic
highlight htmlArg cterm=italic

" Wrapping
set nowrap                      " No wrapping
set linebreak                   " When wrapping, only at certain characters
set textwidth=0                 " Turn off physical line wrapping
set wrapmargin=0                " Turn off physical line wrapping

" Invisible characters
nmap <leader>l :set list!<CR>   " Toggle hidden characters
set nolist                      " Hide by default
set listchars=tab:▸\ ,trail:-,extends:>,precedes:<,nbsp:⎵,eol:¬

" Completion menu
set completeopt=longest,menuone " Inserts the longest common text and
                                " show menu even with only one item

" Toggle paste mode
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>

" Spell checking
set spelllang=en_us             " Default language
set complete+=kspell            " Word completion
map <F7> :setlocal spell!<CR>   " Toggle spell check

" Enable spell checking
autocmd FileType gitcommit setlocal spell
autocmd FileType markdown setlocal spell
autocmd FileType text setlocal spell
autocmd FileType rst setlocal spell

" Doxygen
autocmd Filetype c,cpp set comments^=:///

" Disable visual bell
set noeb vb t_vb=

" Treat given characters as a word boundary
set iskeyword-=.                " '.' is an end of word designator
set iskeyword-=#                " '#' is an end of word designator

" Wrapping
vmap Q gq                       " Wrap the current visual selection
nmap Q gqap                     " Wrap the current paragraph

" Cycle through buffers with (ctrl) tab
nnoremap <silent> <Tab> :bnext<CR>
nnoremap <silent> <S-Tab> :bprevious<CR>

" Close window
nmap <silent> <Leader>wd <C-w>q " Close the current window

" Splits
set splitbelow                  " Horizontal split below
set splitright                  " Vertical split right

" Copy/Paste
set clipboard=unnamed           " Use system clip board

" Ctags
set tags=tags;                  " Find tags recursively

" Joining
set nojoinspaces                " Only one space when joining lines
if has('patch-7.3.541')
    set formatoptions+=j        " Remove comment leader when joining lines
endif

" Undo
if has('persistent_undo')
    set undofile                " Persistent undo
    set undodir=~/.vim/undo     " Location to store undo history
    set undolevels=1000         " Max number of changes
    set undoreload=10000        " Max lines to save for undo on a buffer reload
endif

" Recognize NASM extension
au BufRead,BufNewFile *.nasm set filetype=nasm

" GUI
if has("gui_running")
    set vb t_vb=                " Disable visual bell
    set guioptions-=L           " Hide scroll bars
    set lines=999 columns=999   " Start maximized
    set guifont=Operator\ Mono\ For\ Powerline:h14
endif

" Copy filename:linenumber to clipboard
nnoremap <leader>yy :let @+=expand('%:t') . ':' . line(".")<CR>

" Remove Trailing Whitespace
autocmd BufWritePre * :%s/\s\+$//e

" Watch my .vimrc
augroup reload_myvimrc
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END

" ---------------------------------------------------------------------------- "
" Plugin Configuration                                                         "
" ---------------------------------------------------------------------------- "

" Close buffer
nnoremap <silent> <Leader>q :Bdelete<CR>
nnoremap <silent> <Leader>bd :Bdelete!<CR>

" Signify
let g:signify_vcs_list = [ 'git', 'hg', 'svn' ]

" FZF
let g:fzf_buffers_jump=1
nnoremap <silent> <C-p> :Files<CR>
nnoremap <silent> <C-b> :Buffers<CR>
vnoremap ag y :Ag <C-R>"<CR>        " Ag for visual selection

" Airline
let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#fnamemod=':t'

" Detect Indent
let g:detectindent_preferred_expandtab=1
let g:detectindent_preferred_indent=2
autocmd BufReadPost * :DetectIndent

" Tagbar
nnoremap <F8> :TagbarToggle<CR>
let g:tagbar_autofocus=0
let g:tagbar_right=1
let g:tagbar_width=35

" NERDTree
let g:NERDTreeIgnore=['\.job$', '^CVS$', '\.orig', '\~$']
let g:NERDTreeShowHidden=1
let g:NERDTreeStatusline="%f"
let g:NERDTreeWinPos="left"
let g:NERDTreeWinSize=35
nnoremap <F9> :NERDTreeFind<CR>
nnoremap <F10> :NERDTreeToggle<CR>

" Close vim if the only window left is a NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" YouCompleteMe
let g:ycm_global_ycm_extra_conf='~/.vim/.ycm_extra_conf.py'
let g:ycm_extra_conf_globlist=['~/.vim/*']
let g:ycm_always_populate_location_list = 0
let g:ycm_auto_trigger=1
let g:ycm_enable_diagnostic_highlighting=1
let g:ycm_enable_diagnostic_signs=1
let g:ycm_max_diagnostics_to_display=10000
let g:ycm_min_num_identifier_candidate_chars=0
let g:ycm_min_num_of_chars_for_completion=2
let g:ycm_open_loclist_on_ycm_diags=1
let g:ycm_show_diagnostics_ui=1
let g:ycm_collect_identifiers_from_tags_files = 1
let g:ycm_filetype_blacklist={
            \ 'vim' : 1,
            \ 'tagbar' : 1,
            \ 'qf' : 1,
            \ 'notes' : 1,
            \ 'markdown' : 1,
            \ 'md' : 1,
            \ 'unite' : 1,
            \ 'text' : 1,
            \ 'vimwiki' : 1,
            \ 'pandoc' : 1,
            \ 'infolog' : 1,
            \ 'mail' : 1
            \}

" YouCompleteMe Omni-Completion
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
autocmd FileType haskell setlocal omnifunc=necoghc#omnifunc

" YouCompleteMe key bindings
nnoremap <F11> :YcmForceCompileAndDiagnostics<CR>
nnoremap <F12> :YcmDiags<CR>

" YcmCompleter Subcommands
nnoremap <silent> <Leader>yd :YcmCompleter GetDoc<CR>
nnoremap <silent> <Leader>yf :YcmCompleter FixIt<CR>
nnoremap <silent> <Leader>yg :YcmCompleter GoTo<CR>
nnoremap <silent> <Leader>yi :YcmCompleter GoToInclude<CR>
nnoremap <silent> <Leader>yt :YcmCompleter GetType<CR>

" AutoFormat
let g:formatdef_clangformat='"clang-format -style=file"'

" Doxygen
let g:DoxygenToolkit_commentType = "C++"

" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_aggregate_errors = 1
let g:syntastic_always_populate_loc_list=1
let g:syntastic_auto_loc_list=1
let g:syntastic_check_on_open=1
let g:syntastic_check_on_wq = 0

" Syntastic Checkers
let g:syntastic_cpp_checkers=['cppcheck']
let g:syntastic_javascript_checkers = ['jshint']
let g:syntastic_python_checkers=['pylint']

" Dispatch
nnoremap <F5> :Make<CR>
