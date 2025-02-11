return {
    {
        "neovim/nvim-lspconfig",
        dependencies = { "saghen/blink.cmp" },
        opts = {
            servers = {
                lua_ls = {},
                cmake = {},
                pyright = {},
                sourcekit = {
                    filetypes = { "swift" },
                },
                clangd = {
                    cmd = { "clangd", "--background-index" },
                },
            },
        },
        config = function(_, opts)
            local lspconfig = require("lspconfig")
            for server, config in pairs(opts.servers) do
                -- passing config.capabilities to blink.cmp merges with the capabilities in your
                -- `opts[server].capabilities, if you've defined it
                config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
                lspconfig[server].setup(config)
            end
        end,
    },
}
