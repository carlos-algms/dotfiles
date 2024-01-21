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

        vim.keymap.set("n", "<leader>xx", trouble.toggle)
        vim.keymap.set("n", "<leader>xd", function()
            trouble.toggle("doucment_diagnotics")
        end)

        vim.keymap.set("n", "<leader>xq", function()
            trouble.toggle("quickfix")
        end)

        vim.keymap.set("n", "[x", function()
            trouble.previous({ skip_groups = true, jump = true })
        end)

        vim.keymap.set("n", "]x", function()
            trouble.next({ skip_groups = true, jump = true })
        end)
    end,
}
