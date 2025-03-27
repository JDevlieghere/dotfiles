return {
    {
        "maxmx03/solarized.nvim",
        lazy = false,
        priority = 1000,
        ---@type solarized.config
        opts = {
            variant = "autumn",
            styles = {
                comments = { italic = true, bold = false },
            },
            on_highlights = function(colors, color)
                ---@type solarized.highlights
                local groups = {
                    SpellBad = { underline = false, strikethrough = false, undercurl = true },
                }
                return groups
            end,
        },
        config = function(_, opts)
            vim.o.termguicolors = true
            vim.o.background = "dark"
            require("solarized").setup(opts)
            vim.cmd.colorscheme("solarized")
        end,
    },
}
