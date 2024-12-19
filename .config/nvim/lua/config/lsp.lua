local lspconfig = require("lspconfig")

lspconfig.cmake.setup({})
lspconfig.pyright.setup({})
lspconfig.sourcekit.setup({
    filetypes = { "swift" },
})
lspconfig.clangd.setup({
    cmd = { "clangd", "--background-index" },
})

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = false,
    signs = true,
    update_in_insert = false,
})
