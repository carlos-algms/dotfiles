return {
    "tomasky/bookmarks.nvim",
    event = "VeryLazy",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },

    config = function()
        -- TODO: save bookmarks per project, `nvim.bookmarks` is a json file saving all bookmarks
        -- Do I need to create a folder, or it gets created automatically?
        require("bookmarks").setup({
            save_file = os.getenv("HOME") .. "/.cache/nvim-bookmarks",
            keywords = {
                ["@t"] = "☑️ ", -- mark annotation startswith @t ,signs this icon as `Todo`
                ["@w"] = "⚠️ ", -- mark annotation startswith @w ,signs this icon as `Warn`
                ["@f"] = "⛏ ", -- mark annotation startswith @f ,signs this icon as `Fix`
                ["@n"] = "󰷉", -- mark annotation startswith @n ,signs this icon as `Note`
            },
            on_attach = function(bufnr)
                local bm = require("bookmarks")
                local map = vim.keymap.set

                map(
                    "n",
                    "<leader>mt",
                    bm.bookmark_toggle,
                    { desc = "Bookmark toogle in current line" }
                )

                map(
                    "n",
                    "<leader>mi",
                    bm.bookmark_ann,
                    { desc = "Add or Edit bookmark annotation" }
                )

                map("n", "<leader>mc", bm.bookmark_clean, {
                    desc = "Clean ALL bookmarks in current buffer",
                })

                map("n", "<leader>mn", bm.bookmark_next, {
                    desc = "Jump to next bookmark in current buffer",
                })

                map("n", "<leader>mp", bm.bookmark_prev, {
                    desc = "Jump to previous bookmark in the current buffer",
                })

                -- map("n", "<leader>ml", bm.bookmark_list, {
                --     desc = "Show bookmarks in a quickfix window",
                -- })

                map("n", "<leader>ml", ":Telescope bookmarks list<CR>", {
                    desc = "Show bookmarks in a quickfix window",
                })
            end,
        })
        require("telescope").load_extension("bookmarks")
    end,
}
