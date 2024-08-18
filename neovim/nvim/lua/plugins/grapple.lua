return {
    {
        "cbochs/grapple.nvim",
        opts = {
            scope = "git_branch",
        },
        event = { "BufReadPost", "BufNewFile" },
        cmd = "Grapple",
        keys = {
            {
                "<leader>a",
                "<cmd>Grapple toggle<cr>",
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
