return {
    {
        "cbochs/grapple.nvim",
        opts = {
            -- cwd - current working directory, mutable
            -- git_branch - git branch, mutable
            -- static - initial working directory, should not change
            scope = "static",
            win_opts = {
                -- Can be fractional
                width = 0.85,
            },
        },

        -- event = { "BufReadPost", "BufNewFile" },

        cmd = "Grapple",
        keys = {
            {
                "<leader>a",
                "<cmd>Grapple tag<cr>", -- "<cmd>Grapple toggle<cr>", toggle was removing the file when added multiple times
                desc = "Grapple toggle tag",
            },
            {
                "<leader>e",
                "<cmd>Grapple toggle_tags<cr>",
                desc = "Grapple open tags window",
            },
            {
                "<leader>1",
                "<cmd>Grapple select index=1<cr>",
                desc = "Grapple select index 1",
            },
            {
                "<leader>2",
                "<cmd>Grapple select index=2<cr>",
                desc = "Grapple select index 2",
            },
            {
                "<leader>3",
                "<cmd>Grapple select index=3<cr>",
                desc = "Grapple select index 3",
            },
            {
                "<leader>4",
                "<cmd>Grapple select index=4<cr>",
                desc = "Grapple select index 4",
            },
            {
                "<leader>5",
                "<cmd>Grapple select index=5<cr>",
                desc = "Grapple select index 5",
            },
            {
                "<leader>6",
                "<cmd>Grapple select index=6<cr>",
                desc = "Grapple select index 6",
            },
            {
                "<leader>7",
                "<cmd>Grapple select index=7<cr>",
                desc = "Grapple select index 7",
            },
            {
                "<leader>8",
                "<cmd>Grapple select index=8<cr>",
                desc = "Grapple select index 8",
            },
            {
                "<leader>9",
                "<cmd>Grapple select index=9<cr>",
                desc = "Grapple select index 9",
            },
        },
    },
}
