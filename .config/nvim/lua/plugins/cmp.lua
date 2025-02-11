return {
    {
        "saghen/blink.cmp",
        -- Use a release tag to download pre-built binaries.
        version = "*",
        ---@type blink.cmp.Config
        opts = {
            keymap = { preset = "super-tab" },
            sources = {
                default = { "lsp", "path", "buffer" },
            },
        },
        opts_extend = { "sources.default" },
    },
}
