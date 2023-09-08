require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    "c",
    "cpp",
    "llvm",
    "lua",
    "query" ,
    "rust",
    "swift",
    "vim",
    "vimdoc",
  },
  auto_install = true,
  sync_install = false,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  }
}
