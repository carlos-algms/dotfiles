return {
    "tpope/vim-commentary",
    event = "VeryLazy",
    config = function()
        -- https://github.com/tpope/vim-commentary?tab=readme-ov-file#faq
        -- autocmd FileType apache setlocal commentstring=#\ %s
        local commentaryGroup = vim.api.nvim_create_augroup(
            "CommentaryAutoCmdGroup",
            { clear = true }
        )

        vim.api.nvim_create_autocmd("FileType", {
            group = commentaryGroup,
            desc = "Set GraphQl comment string",
            pattern = "graphql",
            callback = function(ev)
                vim.bo[ev.buf].commentstring = "# %s"
            end,
        })

        vim.api.nvim_create_autocmd("FileType", {
            group = commentaryGroup,
            desc = "Set Prisma comment string",
            pattern = "prisma",
            callback = function(ev)
                vim.bo[ev.buf].commentstring = "// %s"
            end,
        })
    end,
}
