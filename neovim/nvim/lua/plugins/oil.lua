return {
    "stevearc/oil.nvim",
    -- Optional dependencies
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    opts = {
        -- https://github.com/stevearc/oil.nvim?tab=readme-ov-file#options
        view_options = {
            show_hidden = true,
        },
        keymaps = {
            ["q"] = "actions.close",
        },
    },
    config = function(_, opts)
        require("oil").setup(opts)

        vim.keymap.set(
            "n",
            "<C-n>",
            "<cmd>Oil<CR>",
            { desc = "Revel current file in Oil" }
        )
    end,
    -- keys = {
    --     {
    --         "<C-n>",
    --         "<cmd>Oil<CR>",
    --         desc = "Revel current file in Oil",
    --     },
    -- },
}
