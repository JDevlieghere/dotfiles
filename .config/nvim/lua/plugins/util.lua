return {
    {
        "folke/persistence.nvim",
        event = "BufReadPre", -- this will only start session saving when an actual file was opened
        opts = {
            dir = vim.fn.stdpath("state") .. "/sessions/", -- directory where session files are saved
            need = 1, -- minimum number of file buffers that need to be open to save
            branch = true, -- use git branch to save session
        },
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {},
        keys = {
            {
                "<leader>?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "Buffer Local Keymaps (which-key)",
            },
        },
    },
}
