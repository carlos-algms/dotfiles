return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        opt = true,
    },
    config = function()
        local opts = {
            options = {
                icons_enabled = true,
                theme = "auto",
            },
            sections = {
                lualine_a = {
                    {
                        "vim.fn.fnamemodify(vim.fn.getcwd(), ':t')",
                    },
                    {
                        "mode",
                        upper = true,
                    },
                },
                lualine_c = {
                    {
                        "filename",
                        path = 1,
                    },
                },
            },
        }

        require("lualine").setup(opts)
    end,
}
