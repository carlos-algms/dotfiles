return {
    "tpope/vim-fugitive",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        local fugitiveWinId = nil
        local telescopeBuiltin = require("telescope.builtin")

        vim.keymap.set(
            "n",
            "<C-S-p>",
            ":Git push<CR>",
            { desc = "[G]it [P]ush" }
        )

        vim.keymap.set("n", "<leader>gs", function()
            vim.cmd("Git")
            fugitiveWinId = vim.api.nvim_get_current_win()
            vim.cmd("wincmd o ")
            vim.cmd("vnew")
            vim.cmd("wincmd 1w")
            vim.api.nvim_win_set_width(fugitiveWinId, 50)
            vim.cmd("norm 0)")
        end, { desc = "Show [g]it [s]tatus", silent = true })

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
                    ":<C-U> wincmd o<CR> :vertical Git commit<CR>",
                    {}
                )
            end,
        })

        local group = vim.api.nvim_create_augroup(
            "UserFugitiveOverrides",
            { clear = true }
        )

        vim.api.nvim_create_autocmd("BufEnter", {
            pattern = "COMMIT_EDITMSG",
            callback = function()
                vim.defer_fn(function()
                    if fugitiveWinId then
                        vim.api.nvim_win_set_width(fugitiveWinId, 50)
                    end
                end, 50)
            end,
            group = group,
        })

        vim.api.nvim_create_autocmd("BufLeave", {
            pattern = "COMMIT_EDITMSG",
            callback = function()
                vim.cmd("vnew")

                if fugitiveWinId then
                    vim.defer_fn(function()
                        vim.api.nvim_set_current_win(fugitiveWinId)
                        vim.api.nvim_win_set_width(fugitiveWinId, 50)
                    end, 50)
                end
            end,
            group = group,
        })
    end,
}
