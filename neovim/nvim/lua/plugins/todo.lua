-- This is normal comment
-- TODO: this is a todo
-- FIX: this is a fix
-- FIXIT: this is a fix
-- BUG: this is a bug
-- PERF: this is a perf improvement
-- HACK: this is a hack
-- WARNING: this is a warning
-- NOTE: this is a note
return {
    "folke/todo-comments.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        -- "folke/trouble.nvim",
    },
    event = "VeryLazy",
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
                color = "#804747", -- can be a hex color, or a named color (see below)
                alt = { "FIXME", "BUG", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
                -- signs = false, -- configure signs for some keywords individually
            },
            FIXIT = {
                icon = " ", -- icon used for the sign, and in search results
                color = "#804747",
                -- color = "#75342e", -- can be a hex color, or a named color
            },
            TODO = { color = "#45617d" },
            PERF = { color = "#544c75" },
            HACK = { color = "#8f653b" },
            WARN = { color = "#8f653b" },
            NOTE = { color = "#45617d" },
        },
        gui_style = {
            fg = "NONE", -- The gui style to use for the fg highlight group.
            bg = "NONE", -- The gui style to use for the bg highlight group.
        },
    },

    config = function(_, opts)
        require("todo-comments").setup(opts)

        for k, v in pairs(opts.keywords) do
            vim.api.nvim_set_hl(0, "TodoBg" .. k, {
                bg = v.color,
                fg = "#1c1c1c",
            })
        end
    end,
}
