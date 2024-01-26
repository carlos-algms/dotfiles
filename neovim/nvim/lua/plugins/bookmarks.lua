return {
    "tomasky/bookmarks.nvim",
    event = "VeryLazy",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },

    config = function()
        local project_path =
            vim.fn.fnamemodify(vim.fn.getcwd(), ":p"):gsub("/", "__")

        local bookmarksPath = os.getenv("HOME")
            .. "/.cache/nvim/nvim-bookmarks/"

        vim.cmd("silent !mkdir -p " .. bookmarksPath)

        local bookmarksFile = bookmarksPath .. project_path .. ".json"

        require("bookmarks").setup({
            -- Save the bookmarks per project
            save_file = bookmarksFile,
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
                    desc = "Show bookmarks with Telescope",
                })
            end,
        })
        require("telescope").load_extension("bookmarks")
    end,
}
