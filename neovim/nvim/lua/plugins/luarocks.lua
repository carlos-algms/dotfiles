return {
    {
        "vhyrro/luarocks.nvim",
        priority = 2000, -- this plugin needs to run before anything else
        enabled = not vim.g.is_ssh
            and (
                vim.fn.executable("lua") == 1
                or vim.fn.executable("luajit") == 1
            ),
        opts = {
            rocks = { "magick" },
        },
    },
}
