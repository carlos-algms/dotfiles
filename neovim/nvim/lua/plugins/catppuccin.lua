return {
    {
        "catppuccin/nvim",
        lazy = false,
        name = "catppuccin",
        priority = 1000,
        enabled = true,
        config = function()
            vim.opt.termguicolors = true
            vim.o.background = "dark"

            require("catppuccin").setup({
                color_overrides = {
                    mocha = {
                        -- base = "#000000",
                        -- mantle = "#000000",
                        -- crust = "#000000",
                    },
                },
                custom_highlights = function(colors)
                    return {
                        Comment = { fg = colors.overlay0 },
                    }
                end,
                integrations = {
                    telescope = {
                        enabled = true,
                    },
                    dropbar = {
                        enabled = true,
                        color_mode = true,
                    },
                },
            })

            vim.cmd.colorscheme("catppuccin")
        end,
    },
}
