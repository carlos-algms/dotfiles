return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        opt = true,
    },
    opts = {
        options = {
            icons_enabled = true,
            theme = "catppuccin",
        },
        sections = {
            lualine_a = {
                {
                    "filename",
                    path = 1,
                },
            },
        },
    },
    config = function(_, opts)
        require("lualine").setup(opts)
    end,
}
