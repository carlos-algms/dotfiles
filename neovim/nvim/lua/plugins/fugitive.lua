return {
    "tpope/vim-fugitive",
    config = function()
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
                    ":<C-U> vertical Git commit<CR>",
                    {}
                )
            end,
        })
    end,
}
