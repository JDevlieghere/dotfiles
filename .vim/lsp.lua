require'lspconfig'.vimls.setup{}
require'lspconfig'.pyls.setup{}
require'lspconfig'.clangd.setup{}

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = false,
    signs = true,
    update_in_insert = false,
  }
)
