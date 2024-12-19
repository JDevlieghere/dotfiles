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
        "romgrk/barbar.nvim",
        dependencies = {
            "lewis6991/gitsigns.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        init = function()
            vim.g.barbar_auto_setup = false
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },
    {
        "nvim-tree/nvim-web-devicons",
        lazy = true,
    },
    "ervandew/supertab",
    "ibhagwan/fzf-lua",
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
