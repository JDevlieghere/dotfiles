local lualine = require("lualine")

lualine.setup({
    options = {
        icons_enabled = true,
        theme = "solarized",
        component_separators = { left = " ", right = " " },
        section_separators = { left = " ", right = " " },
    },
    sections = {
        lualine_b = { "branch" },
    },
})
