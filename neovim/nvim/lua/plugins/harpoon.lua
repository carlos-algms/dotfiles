return {
    "ThePrimeagen/harpoon",
    -- event = "VeryLazy",

    enabled = false,

    keys = {
        {
            "<leader>a",
            function()
                require("harpoon.mark").add_file()
            end,
            mode = "n",
            desc = "Add current file to Harpoon",
        },

        {
            "<C-e>",
            function()
                require("harpoon.ui").toggle_quick_menu()
            end,
            mode = "n",
            desc = "Toggle Harpoon [E]xplorer",
        },

        {
            "<leader>1",
            function()
                require("harpoon.ui").nav_file(1)
            end,
            mode = "n",
            desc = "Go To the 1st file on Harpoon",
        },
        {
            "<leader>2",
            function()
                require("harpoon.ui").nav_file(2)
            end,
            mode = "n",
            desc = "Go To the 2nd file on Harpoon",
        },
        {
            "<leader>3",
            function()
                require("harpoon.ui").nav_file(3)
            end,
            mode = "n",
            desc = "Go To the 3rd file on Harpoon",
        },
        {
            "<leader>4",
            function()
                require("harpoon.ui").nav_file(4)
            end,
            mode = "n",
            desc = "Go to the 4th file on Harpoon",
        },
    },
}
