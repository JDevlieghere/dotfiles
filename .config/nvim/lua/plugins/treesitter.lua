return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        lazy = false,
        opts = {
            highlight = { enable = true },
            indent = { enable = true },
            install_dir = vim.fn.stdpath("data") .. "/site",
        },
        config = function(_, opts)
            local TS = require("nvim-treesitter")

            TS.install({
                "bash",
                "c",
                "cpp",
                "diff",
                "json",
                "llvm",
                "lua",
                "luadoc",
                "markdown",
                "markdown_inline",
                "printf",
                "python",
                "query",
                "regex",
                "rust",
                "swift",
                "toml",
                "typescript",
                "vim",
                "vimdoc",
                "xml",
                "yaml",
            })

            TS.setup(opts)

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("lazyvim_treesitter", { clear = true }),
                callback = function(ev)
                    local lang = vim.treesitter.language.get_lang(ev.match)
                    if not lang then
                        return
                    end

                    if vim.treesitter.query.get(lang, "highlights") then
                        vim.treesitter.start(ev.buf)
                    end

                    if vim.treesitter.query.get(lang, "indents") then
                        vim.opt_local.indentexpr = 'v:lua.require("nvim-treesitter").indentexpr()'
                    end

                    if vim.treesitter.query.get(lang, "folds") then
                        vim.opt_local.foldmethod = "expr"
                        vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
                    end
                end,
            })
        end,
    },
}
