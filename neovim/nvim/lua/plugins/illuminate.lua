return {
    "RRethy/vim-illuminate",
    config = function()
        local illuminate = require("illuminate")
        vim.keymap.set(
            "n",
            "]s",
            illuminate.goto_next_reference,
            { desc = "Go to next reference" }
        )
        vim.keymap.set(
            "n",
            "[s",
            illuminate.goto_prev_reference,
            { desc = "Go to previous reference" }
        )
    end,
}
