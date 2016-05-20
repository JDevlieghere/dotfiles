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
Plug 'chiel92/vim-autoformat'
Plug 'ciaranm/detectindent'
Plug 'easymotion/vim-easymotion'
Plug 'fatih/vim-go', { 'for': 'go' }
Plug 'godlygeek/tabular' | Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
Plug 'jdevlieghere/llvm.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'majutsushi/tagbar'
Plug 'mbbill/undotree'
Plug 'mhinz/vim-signify'
Plug 'mhinz/vim-startify'
Plug 'moll/vim-bbye'
Plug 'octol/vim-cpp-enhanced-highlight', { 'for': 'cpp' }
Plug 'racer-rust/vim-racer', { 'for': 'rust' }
Plug 'rhysd/vim-grammarous', { 'on': 'GrammarousCheck' }
Plug 'rking/ag.vim'
Plug 'rust-lang/rust.vim', { 'for': 'rust' }
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree', { 'on':  ['NERDTreeToggle', 'NERDTreeFind'] }
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

if has("nvim")
    Plug 'benekastah/neomake'
else
    Plug 'scrooloose/syntastic'
    Plug 'tpope/vim-dispatch'
endif

if has("python")
    Plug 'valloric/youcompleteme', { 'do': './install.py --clang-completer --gocode-completer --tern-completer --racer-completer' }
endif

if has("lua")
    Plug 'jeaye/color_coded', { 'do': 'cmake . && make && make install' }
endif

call plug#end()

" ---------------------------------------------------------------------------- "
" Vanilla Vim                                                                  "
" ---------------------------------------------------------------------------- "

" Colors & Syntax
syntax enable                   " Enable syntax highlighting
set background=dark             " Dark background color

" Color Scheme
colorscheme solarized
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
set cm=blowfish                 " Better crypto

" Temp Files
set nobackup                    " No backup file
set noswapfile                  " No swap file

" Line Numbers
set nu                          " Show line numbers
"set rnu                        " Relative line numbers

" Rulers
set colorcolumn=80,120          " Show ruler columns

" Cursor
autocmd WinEnter * setlocal cursorline
autocmd WinLeave * setlocal nocursorline

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
cnoreabbrev W w                 " :W
cnoreabbrev Q q                 " :Q

" Wrapping
set nowrap                      " No wrapping
set linebreak                   " When wrapping, only at certain characters
set textwidth=0                 " Turn off physical line wrapping
set wrapmargin=0                " Turn off physical line wrapping

" Invisible Characters
nmap <leader>l :set list!<CR>   " Toggle hidden characters
set nolist                      " Hide by default
set listchars=tab:▸\ ,trail:-,extends:>,precedes:<,nbsp:⎵,eol:¬

" Completion Menu
set completeopt=longest,menuone " Inserts the longest common text and
                                " show menu even with only one item

" Toggle Paste Mode
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>

" Spell Checking
set spelllang=en_us             " Default language
set complete+=kspell            " Word completion
map <F7> :setlocal spell!<CR>   " Toggle spell check

" Disable Bells
set noeb vb t_vb=

" Treat underscore as a word boundary
set iskeyword-=_                " '_' is an end of word designator
set iskeyword-=.                " '.' is an end of word designator
set iskeyword-=#                " '#' is an end of word designator
set iskeyword-=-                " '-' is an end of word designator

" Wrapping
vmap Q gq
nmap Q gqap

" Cycle through buffers
nnoremap <silent> <Tab> :bnext<CR>
nnoremap <silent> <S-Tab> :bprevious<CR>

" Close window
nnoremap <silent> <F3>  <C-w>q
nmap <silent> <Leader>wd <C-w>q

" Splits
set splitbelow
set splitright

" Enable Copy/Paste
set clipboard=unnamed
vmap <C-c> "+yi
vmap <C-x> "+c
vmap <C-v> c<ESC>"+p
imap <C-v> <ESC>"+pa

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

" GUI
if has("gui_running")
    set vb t_vb=
    set guioptions-=L           " Hide scroll bars
    set lines=999 columns=999   " Start maximized
    if has("gui_gtk2")
        set guifont=Source\ Code\ Pro\ for\ Powerline:h12,Source\ Code\ Pro:h12
    elseif has("gui_macvim")
        set guifont=Source\ Code\ Pro\ for\ Powerline:h14,Source\ Code\ Pro:h14
    elseif has("gui_win32")
        set guifont=Sauce_Code_Powerline:h11:cANSI,Source_Code_Pro:h11:cANSI
    endif
endif

" Remove Trailing Whitespace
autocmd BufWritePre * :%s/\s\+$//e

" Watch my .vimrc
augroup reload_myvimrc
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END

" ---------------------------------------------------------------------------- "
" Functions                                                                    "
" ---------------------------------------------------------------------------- "

" Highlight duplicate lines
" http://stackoverflow.com/questions/1268032/marking-duplicate-lines
function! HighlightRepeats() range
    let lineCounts={}
    let lineNum=a:firstline
    while lineNum <= a:lastline
        let lineText=getline(lineNum)
        if lineText != ""
            let lineCounts[lineText]=(has_key(lineCounts, lineText) ? lineCounts[lineText] : 0) + 1
        endif
        let lineNum=lineNum + 1
    endwhile
    exe 'syn clear Repeat'
    for lineText in keys(lineCounts)
        if lineCounts[lineText] >= 2
            exe 'syn match Repeat "^' . escape(lineText, '".\^$*[]') . '$"'
        endif
    endfor
endfunction
command! -range=% HighlightRepeats <line1>,<line2>call HighlightRepeats()

" Switch between source and header files using ctags
" Rudimentary approach: only supports .cpp and .h
function! Switch()
    let baseName=expand('%:t:r')
    let extension=expand('%:e')
    if extension =~ 'c'
        execute "tag " . baseName . '.h'
    else
        execute "tag " . baseName . '.cpp'
    endif
endfunction
nmap <silent> <Leader>fs :call Switch()<CR>

" ---------------------------------------------------------------------------- "
" Plugin Configuration                                                         "
" ---------------------------------------------------------------------------- "

" Close buffer
nnoremap <silent> <F4>   :Bdelete<CR>
nmap <silent> <Leader>bd :Bdelete<CR>

" FZF
let g:fzf_buffers_jump=1
nnoremap <silent> <C-p> :Files<CR>
nnoremap <silent> <C-b> :Buffers<CR>

" Airline
set laststatus=2                " Alwasy display statusline
let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#fnamemod=':t'

" Detect Indent
let g:detectindent_preferred_expandtab=1
let g:detectindent_preferred_indent=4
autocmd BufReadPost * :DetectIndent

" Tagbar
nnoremap <F8> :TagbarToggle<CR>
let g:tagbar_autofocus=0
let g:tagbar_right=1
let g:tagbar_width=35
if !has("nvim")
    autocmd VimEnter * nested :TagbarOpen
endif

" NERDTree
let NERDTreeWinPos="left"
let NERDTreeWinSize=35
let NERDTreeIgnore=['\.job$', '^CVS$', '\.orig', '\~$']
let g:NERDTreeStatusline="%f"
nnoremap <F9> :NERDTreeFind<CR>
nnoremap <F10> :NERDTreeToggle<CR>

" YouCompleteMe {
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
" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
autocmd FileType haskell setlocal omnifunc=necoghc#omnifunc
nnoremap <F12> :YcmDiags<CR>
nnoremap <silent> <Leader>yd :YcmDiags<CR>
nnoremap <silent> <Leader>yf :YcmCompleter FixIt<CR>
nnoremap <silent> <Leader>yg :YcmCompleter GoTo<CR>

" Auto Format
let g:formatdef_clangformat='"clang-format -style=file"'

" Markdown
let g:vim_markdown_folding_disabled=1

" Startify
autocmd User Startified setlocal buftype=
let g:startify_change_to_dir = 0
if has("nvim")
    set viminfo+=n~/.nvim/tmpfiles/viminfo
else
    set viminfo='100,n$HOME/.vim/files/info/viminfo
endif

" EasyMotion
nmap s <Plug>(easymotion-s2)
nmap t <Plug>(easymotion-t2)

if has("nvim")
    " Neomake
    nnoremap <F5> :Neomake<CR>
    let g:neomake_javascript_enabled_makers = ['jshint']
    let g:neomake_python_enabled_makers = ['pylint']
else
    " Syntastic
    set statusline+=%#warningmsg#
    set statusline+=%{SyntasticStatuslineFlag()}
    set statusline+=%*
    let g:syntastic_always_populate_loc_list=1
    let g:syntastic_auto_loc_list=1
    let g:syntastic_check_on_open=1
    let g:syntastic_cpp_checkers=['cppcheck']
    let g:syntastic_javascript_checkers = ['jshint']
    let g:syntastic_python_checkers=['pylint']

    " Dispatch
    nnoremap <F5> :Make<CR>
endif
