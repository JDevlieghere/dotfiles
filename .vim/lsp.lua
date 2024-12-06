local cmp = require'cmp'

cmp.setup {
  mapping = {
    ['<Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end,
    ['<S-Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end
  },
  sources = {
    { name = 'nvim_lsp' }
  }
}

local capabilities = require('cmp_nvim_lsp').default_capabilities()
local lspconfig = require'lspconfig'

lspconfig.cmake.setup{}
lspconfig.pyright.setup{}
lspconfig.sourcekit.setup{
  filetypes = { "swift" }
}
lspconfig.clangd.setup{
  cmd = { "clangd", "--background-index" },
}

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = false,
    signs = true,
    update_in_insert = false,
  }
)
