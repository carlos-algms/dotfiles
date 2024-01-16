return {
    "RRethy/vim-illuminate",
    enabled = true,
    config = function()
        local illuminate = require("illuminate")

        illuminate.configure({
            providers = {
                "lsp",
                "treesitter",
                -- "regex",
            },
        })

        vim.cmd([[ hi! clear IlluminatedWordText ]])
        vim.cmd([[ hi! clear IlluminatedWordWrite ]])
        vim.cmd([[ hi! clear IlluminatedWordRead ]])

        vim.cmd([[ hi! IlluminatedWordText guibg=#393b4e ]])
        vim.cmd([[ hi! link IlluminatedWordRead IlluminatedWordText ]])
        vim.cmd([[ hi! link IlluminatedWordWrite IlluminatedWordText ]])

        vim.keymap.set(
            "n",
            "]r",
            illuminate.goto_next_reference,
            { desc = "Go to next reference" }
        )

        vim.keymap.set(
            "n",
            "[r",
            illuminate.goto_prev_reference,
            { desc = "Go to previous reference" }
        )
    end,
}
