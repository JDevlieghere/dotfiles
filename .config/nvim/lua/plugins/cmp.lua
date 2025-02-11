return {
    {
        "saghen/blink.cmp",
        opts = {
            keymap = { preset = "super-tab" },
            sources = {
                default = { "lsp", "path", "buffer" },
            },
        },
        opts_extend = { "sources.default" },
    },
}
