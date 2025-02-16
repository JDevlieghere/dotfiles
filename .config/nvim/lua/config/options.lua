-- Enable 24-bit RGB color in the TUI.
vim.o.termguicolors = true

-- Assume a dark terminal background.
vim.o.background = "dark"

-- Shows the effects of a command incrementally in the buffer and off-screen
-- results in a preview window.
vim.o.inccommand = "split"

-- Use diagonal lines for deleted lines in diff-mode.
vim.opt.fillchars:append { diff = "╱" }

-- Change leader to space.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.cmd("source ~/.vimrc")
