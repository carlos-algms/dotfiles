return {
    "tpope/vim-fugitive",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        local telescopeBuiltin = require("telescope.builtin")

        vim.keymap.set(
            "n",
            "<leader>gs",
            ":Git<CR>:17wincmd _<CR>",
            { desc = "Show [g]it [s]tatus" , silent = true}
        )

        vim.keymap.set(
            "n",
            "<leader>gb",
            telescopeBuiltin.git_branches,
            { desc = "Show [g]it [b]ranches" }
        )

        vim.keymap.set(
            "n",
            "<leader>gd",
            ":Gvdiffsplit!<CR>",
            { desc = "Show [g]it [d]iff for current file" }
        )

        vim.api.nvim_create_autocmd("FileType", {
            desc = "Fugitive overrides",
            pattern = { "fugitive" },
            group = vim.api.nvim_create_augroup(
                "UserFugitive",
                { clear = true }
            ),
            callback = function(ev)
                vim.api.nvim_buf_set_keymap(
                    ev.buf,
                    "n",
                    "cc",
                    ":<C-U> tab Git commit<CR>",
                    {}
                )
            end,
        })
    end,
}
