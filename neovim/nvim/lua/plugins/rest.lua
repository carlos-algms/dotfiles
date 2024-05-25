return {
    {
        "rest-nvim/rest.nvim",
        ft = "http",
        dependencies = {
            "nvim-neotest/nvim-nio",
            {
                "vhyrro/luarocks.nvim",
                priority = 1000,
                config = true,
                opts = {
                    rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
                },
            },
        },
        config = function()
            ---@diagnostic disable-next-line: missing-fields
            require("rest-nvim").setup({
                keybinds = {
                    {
                        "R",
                        "<cmd>Rest run<cr>",
                        "Run request under the cursor",
                    },
                },
            })

            -- Keep the hightlights here to only load them when the plugin is loaded
            vim.cmd([[ hi! link httpResultMethod Function ]])
            vim.cmd([[ hi! link httpResultPath String ]])
            vim.cmd([[ hi! link @string.special.url.http String ]])
        end,
    },
}
