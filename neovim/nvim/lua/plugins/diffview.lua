-- disabled as it doesn't have:
-- 1. go to next/prev changes as [c and ]c, same as vim-fugitive
-- 2. does not offer a commit command
return {
    "sindrets/diffview.nvim",
    enabled = true,
    config = function()
        local actions = require("diffview.actions")

        vim.keymap.set(
            "n",
            "<leader>gs",
            ":DiffviewOpen<cr>",
            { silent = true }
        )

        local quitDiffViewKeymap = {
            "n",
            "gq",
            ":tabclose<cr>",
            { desc = "Close the Diffview" },
        }

        local commitKeyMap = {
            "n",
            "cc",
            ":tab G commit<cr>",
            { desc = "Commit staged files" },
        }

        require("diffview").setup({
            default_args = {
                DiffviewOpen = { "--imply-local" },
            },
            file_panel = {
                listing_style = "list",
            },
            keymaps = {
                disable_defaults = false, -- Disable the default keymaps
                file_panel = {
                    quitDiffViewKeymap,
                    commitKeyMap,

                    {
                        "n",
                        "<cr>",
                        function()
                            actions.select_entry()
                            vim.cmd("wincmd 2w")
                            vim.cmd("norm gg")
                            vim.cmd("wincmd 3w")
                            vim.cmd("norm gg]c")
                        end,
                        { desc = "Open the diff for the selected entry" },
                    },
                },
                view = {
                    quitDiffViewKeymap,
                    commitKeyMap,
                    {
                        "n",
                        "s",
                        actions.toggle_stage_entry,
                        { desc = "Stage / unstage the selected entry" },
                    },
                },
            },
        })
    end,
}
