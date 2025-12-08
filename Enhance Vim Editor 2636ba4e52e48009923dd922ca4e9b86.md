# Enhance Vim Editor

Create a `.vimrc` file at `/home/user` directory and fill it with below content, then restart terminal session.

```bash
" ===== Basic Settings =====
set number                  " Show line numbers
set relativenumber          " Relative line numbers
set tabstop=4               " Display width of tab
set shiftwidth=4            " Indent by 4 spaces
set expandtab               " Use spaces instead of tabs
set autoindent              " Keep indentation on new lines
set smartindent             " Smarter autoindenting
set cursorline              " Highlight current line
set clipboard=unnamedplus   " Use system clipboard
set mouse=a                 " Enable mouse support
set nowrap                  " Don't wrap lines

" ===== Search =====
set hlsearch                " Highlight search results
set incsearch               " Incremental search
set ignorecase              " Case insensitive search
set smartcase               " Case sensitive if uppercase used

" ===== Appearance =====
syntax on                   " Enable syntax highlighting
set termguicolors           " Use true colors in terminal
set background=dark         " Set background to dark (for themes)
colorscheme desert          " Basic color scheme (can change)

" ===== File handling =====
set nobackup                " Disable backup files
set nowritebackup           " Disable write backup files
set noswapfile              " Disable swap files

" ===== Status line =====
set laststatus=2            " Always show status line
set showcmd                 " Show command in status line
set ruler                   " Show cursor position

" ===== Useful Mappings =====
nnoremap <Space> :noh<CR>   " Clear search highlights with Space
nnoremap <C-s> :w<CR>       " Ctrl+S to save
inoremap <C-s> <Esc>:w<CR>a

" ===== Plugin Support =====
filetype plugin indent on   " Enable file-type plugins and indentation
```