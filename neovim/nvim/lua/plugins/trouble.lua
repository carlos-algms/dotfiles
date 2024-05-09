return {
    "folke/trouble.nvim",

    dependencies = { "nvim-tree/nvim-web-devicons" },

    cmd = {
        "Trouble",
        "TroubleToggle",
        "TroubleClose",
        "TroubleRefresh",
    },

    keys = {
        {
            "<leader>xx",
            "<cmd>TroubleToggle<cr>",
            desc = "Trouble toggle",
            silent = true,
        },

        {
            "<leader>xd",
            function()
                require("trouble").toggle("document_diagnostics")
            end,
            desc = "Trouble document diagnostics",
            silent = true,
        },

        {
            "<leader>xw",
            function()
                require("trouble").toggle("workspace_diagnostics")
            end,
            desc = "Trouble workspace diagnostics",
            silent = true,
        },

        {
            "<leader>xq",
            function()
                require("trouble").toggle("quickfix")
            end,
            desc = "Trouble quickfix",
            silent = true,
        },

        {
            "<leader>xl",
            function()
                require("trouble").toggle("loclist")
            end,
            desc = "Trouble loclist",
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

    config = function()
        local trouble = require("trouble")
        trouble.setup({
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        })
    end,
}
