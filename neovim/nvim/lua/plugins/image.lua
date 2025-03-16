return {
    {
        "3rd/image.nvim",
        enabled = not vim.g.is_ssh,
        event = "VeryLazy",
        dependencies = {
            "vhyrro/luarocks.nvim",
        },
        opts = {},
    },
}
