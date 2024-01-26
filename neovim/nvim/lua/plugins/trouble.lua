return {
    "folke/trouble.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local trouble = require("trouble")
        trouble.setup({
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        })

        vim.keymap.set(
            "n",
            "<leader>xx",
            trouble.toggle,
            { desc = "Trouble toggle", silent = true }
        )

        vim.keymap.set("n", "<leader>xd", function()
            trouble.toggle("document_diagnostics")
        end, {
            desc = "Trouble show document diagnostics",
            silent = true,
        })

        vim.keymap.set("n", "<leader>xw", function()
            trouble.toggle("workspace_diagnostics")
        end, {
            desc = "Trouble show workspace diagnostics",
            silent = true,
        })

        vim.keymap.set("n", "<leader>xq", function()
            trouble.toggle("quickfix")
        end, { desc = "Trouble show quickfix", silent = true })

        vim.keymap.set("n", "[x", function()
            trouble.previous({ skip_groups = true, jump = true })
        end, { desc = "Trouble previous", silent = true })

        vim.keymap.set("n", "]x", function()
            trouble.next({ skip_groups = true, jump = true })
        end, { desc = "Trouble next", silent = true })
    end,
}
