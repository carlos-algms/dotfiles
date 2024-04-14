return {
    "stevearc/oil.nvim",
    opts = {
        -- https://github.com/stevearc/oil.nvim?tab=readme-ov-file#options
        view_options = {
            show_hidden = true,
        },
        keymaps = {
            ["q"] = "actions.close",
        },
    },
    -- Optional dependencies
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    keys = {
        {
            "<C-n>",
            "<cmd>Oil<CR>",
            desc = "Revel current file in Oil",
        },
    },
}
