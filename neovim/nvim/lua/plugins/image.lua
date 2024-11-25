return {
    {
        "vhyrro/luarocks.nvim",
        priority = 1001, -- this plugin needs to run before anything else
        enabled = not vim.g.is_ssh,
        opts = {
            rocks = { "magick" },
        },
    },

    {
        "3rd/image.nvim",
        enabled = not vim.g.is_ssh,
        event = "VeryLazy",
        dependencies = {
            "vhyrro/luarocks.nvim",
        },
        opts = {},
        config = function(_, opts)
            require("image").setup(opts)
        end,
    },
}
