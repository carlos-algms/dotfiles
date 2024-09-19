return {
    {
        "cbochs/grapple.nvim",
        opts = {
            -- cwd - current working directory, mutable
            -- git_branch - git branch, mutable
            -- static - initial working directory, should not change
            scope = "static", -- "git_branch",
        },
        event = { "BufReadPost", "BufNewFile" },
        cmd = "Grapple",
        keys = {
            {
                "<leader>a",
                "<cmd>Grapple tag<cr>", -- "<cmd>Grapple toggle<cr>", toggle was removing the file when added multiple times
                desc = "Grapple toggle tag",
            },
            {
                "<C-e>",
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
        },
    },
}
