return {
    {
        "3rd/image.nvim",
        -- enabled = not vim.g.is_ssh,
        enabled = false,

        event = "VeryLazy",
        dependencies = {
            "vhyrro/luarocks.nvim",
        },
        opts = {
            -- kitty_method = "normal",
            -- backend = "kitty",
            -- processor = "magick_cli",
            hijack_file_patterns = {
                "*.png",
                "*.jpg",
                "*.jpeg",
                "*.gif",
                "*.webp",
                "*.avif",
                "*.svg",
            },
        },
    },
}
