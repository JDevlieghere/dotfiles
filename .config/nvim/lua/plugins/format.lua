return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "black" },
            rust = { "rustfmt" },
            c = { "clang-format" },
            cpp = { "clang-format" },
            objc = { "clang-format" },
            objcpp = { "clang-format" },
            tablegen = { "clang-format" },
        },
        default_format_opts = {
            lsp_format = "fallback",
        },
    },
}
