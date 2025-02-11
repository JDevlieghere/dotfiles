return {
    {
        "romgrk/barbar.nvim",
        dependencies = {
            "lewis6991/gitsigns.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        init = function()
            vim.g.barbar_auto_setup = false
        end,
        opts = {
            -- Disable animations
            animation = false,
        },
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                icons_enabled = true,
                theme = "solarized",
                component_separators = { left = " ", right = " " },
                section_separators = { left = " ", right = " " },
            },
            sections = {
                lualine_b = { "branch" },
            },
        },
    },
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        ---@type snacks.Config
        opts = {
            dashboard = { enabled = true },
            notifier = { enabled = true },
        },
    },
}
