require("conform").setup({
    formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        rust = { "rustfmt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        objc = { "clang-format" },
        objcpp = { "clang-format" },
    },
    default_format_opts = {
        lsp_format = "fallback",
    },
})

vim.api.nvim_create_user_command("Autoformat", function(args)
    local range = nil
    if args.count ~= -1 then
        local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
        range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
        }
    end
    require("conform").format({ async = true, lsp_format = "fallback", range = range })
end, { range = true })
