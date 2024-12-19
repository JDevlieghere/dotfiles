vim.o.termguicolors = true
vim.o.background = "dark"
vim.o.wildoptions = vim.o.wildoptions .. ",pum"
vim.o.inccommand = "split"

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.cmd("source ~/.vimrc")
