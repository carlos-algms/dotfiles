return {
    "folke/trouble.nvim",

    dependencies = { "nvim-tree/nvim-web-devicons" },

    cmd = { "Trouble" },

    keys = {
        {
            "<leader>xx",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "Diagnostics (Trouble)",
            silent = true,
        },

        {
            "<leader>xd",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "Buffer Diagnostics (Trouble)",
            silent = true,
        },

        {
            "<leader>xw",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "Workspace Diagnostics (Trouble)",
            silent = true,
        },

        {
            "<leader>xq",
            "<cmd>Trouble qflist toggle<cr>",
            desc = "Quickfix List (Trouble)",
            silent = true,
        },

        {
            "<leader>xl",
            "<cmd>Trouble loclist toggle<cr>",
            desc = "Location List (Trouble)",
            silent = true,
        },

        {
            "[x",
            function()
                require("trouble").previous({ skip_groups = true, jump = true })
            end,
            desc = "Trouble previous",
            silent = true,
        },

        {
            "]x",
            function()
                require("trouble").next({ skip_groups = true, jump = true })
            end,
            desc = "Trouble next",
            silent = true,
        },
    },

    opts = {},
}
