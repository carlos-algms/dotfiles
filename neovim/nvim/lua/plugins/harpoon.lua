return {
    "ThePrimeagen/harpoon",
    config = function()
        local mark = require("harpoon.mark")
        local ui = require("harpoon.ui")
        local term = require("harpoon.term")

        vim.keymap.set(
            "n",
            "<leader>a",
            mark.add_file,
            { desc = "[A]dd current file to Harpoon" }
        )
        vim.keymap.set(
            "n",
            "<C-e>",
            ui.toggle_quick_menu,
            { desc = "Toggle Harpoon [E]xplorer" }
        )
        vim.keymap.set(
            "n",
            "<leader>1",
            function() ui.nav_file(1) end,
            { desc = "Go To to 1st file on Harpoon" }
        )
        vim.keymap.set(
            "n",
            "<leader>2",
            function() ui.nav_file(2) end,
            { desc = "Go To to 2nd file on Harpoon" }
        )
        vim.keymap.set(
            "n",
            "<leader>3",
            function() ui.nav_file(3) end,
            { desc = "Go To to 3rd file on Harpoon" }
        )
        vim.keymap.set(
            "n",
            "<leader>4",
            function() term.gotoTerminal(1) end,
            { desc = "Go to 1st terminal on Harpoon" }
        )
    end,
}
