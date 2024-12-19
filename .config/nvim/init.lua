-- Configure options before loading lazy.nvim so that mappings are correct.
require("config.options")

-- Setup lazy.nvim
require("config.lazy")

-- Configure plugins
require("config.barbar")
require("config.cmp")
require("config.conform")
require("config.dap")
require("config.fzf")
require("config.git")
require("config.lsp")
require("config.lualine")
require("config.treesitter")
