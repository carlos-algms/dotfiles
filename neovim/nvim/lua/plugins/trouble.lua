return {
    "folke/trouble.nvim",

    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },

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
                require("trouble").prev({ skip_groups = true, jump = true })
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
        require("trouble").setup({
            auto_refresh = false,
            -- The LSP base mode for:
            -- * lsp_definitions, lsp_references, lsp_implementations
            -- * lsp_type_definitions, lsp_declarations, lsp_command
            lsp_base = {
                params = {
                    -- I want to include current to fully circle around the results
                    include_current = true,
                },
            },
            -- modes = {
            --     lsp_incoming_calls = {
            --         auto_refresh = false,
            --     },
            -- },
        })
    end,
}
