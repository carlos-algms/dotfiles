return {
    {
        "vhyrro/luarocks.nvim",
        priority = 2000, -- this plugin needs to run before anything else
        enabled = vim.fn.executable("lua") == 1,
        opts = {
            rocks = { "magick" },
        },
    },
}
