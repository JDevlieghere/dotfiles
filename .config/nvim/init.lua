-- Configure options before loading lazy.nvim so that mappings are correct.
require("config.options")

-- Setup lazy.nvim
require("config.lazy")

-- Configure plugins
require("config.format")
require("config.lsp")
require("config.notifier")
