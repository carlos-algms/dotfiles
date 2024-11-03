return {
    "folke/todo-comments.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "folke/trouble.nvim",
    },
    keys = {
        {
            "<leader>xt",
            "<cmd>Trouble todo filter = {tag = { FIXIT }}<cr>",
            desc = "Trouble FIXIT list",
            silent = true,
        },
        {
            "<leader>tt",
            "<cmd>TodoTelescope keywords=FIXIT<cr>",
            desc = "Telescope FIX list ",
            silent = true,
        },
    },
    opts = {
        keywords = {
            FIX = {
                icon = " ", -- icon used for the sign, and in search results
                color = "error", -- can be a hex color, or a named color (see below)
                alt = { "FIXME", "BUG", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
                -- signs = false, -- configure signs for some keywords individually
            },
            FIXIT = {
                icon = " ", -- icon used for the sign, and in search results
                color = "error",
                -- color = "#75342e", -- can be a hex color, or a named color
            },
        },
    },
}
