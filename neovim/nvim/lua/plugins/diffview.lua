-- disabled as it doesn't have:
-- 1. go to next/prev changes as [c and ]c, same as vim-fugitive
-- 2. does not offer a commit command
return {
    "sindrets/diffview.nvim",
    enabled = false,
    config = function()
        local actions = require("diffview.actions")

        require("diffview").setup({
            file_panel = {
                listing_style = "list",
            },
            keymaps = {
                disable_defaults = false, -- Disable the default keymaps
                file_panel = {
                    {
                        "n",
                        "<cr>",
                        function()
                            actions.select_entry()
                            vim.cmd("wincmd 3w") -- jump to the diff window
                        end,
                        { desc = "Open the diff for the selected entry" },
                    },
                },
            },
        })
    end,
}
