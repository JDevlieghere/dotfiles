return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = function()
            require("nvim-treesitter.install").update()()
        end,
        opts = {
            ensure_installed = {
                "c",
                "cpp",
                "llvm",
                "lua",
                "query",
                "rust",
                "swift",
                "typescript",
                "vim",
                "vimdoc",
            },
            auto_install = true,
            sync_install = false,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
        },
    },
}
