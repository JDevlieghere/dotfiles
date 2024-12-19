return {
    -- the colorscheme should be available when starting Neovim
    {
        "ishan9299/nvim-solarized-lua",
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd([[ colorscheme solarized ]])
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        build = function()
            require("nvim-treesitter.install").update()()
        end,
    },
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
        },
    },
    {
        "nvim-tree/nvim-web-devicons",
        lazy = true,
    },
    "ap/vim-buftabline",
    "ervandew/supertab",
    "ibhagwan/fzf-lua",
    "itchyny/lightline.vim",
    "lewis6991/gitsigns.nvim",
    "llvm/llvm.vim",
    "mbbill/undotree",
    "mfussenegger/nvim-dap",
    "moll/vim-bbye",
    "neovim/nvim-lspconfig",
    "stevearc/conform.nvim",
    "tpope/vim-commentary",
    "tpope/vim-fugitive",
    "tpope/vim-sleuth",
    "tpope/vim-surround",
    "vim-scripts/doxygentoolkit.vim",
}
