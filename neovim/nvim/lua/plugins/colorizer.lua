return {
    "norcalli/nvim-colorizer.lua",
    enabled = true,

    ft = {
        "css",
        "scss",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "html",
    },

    config = function()
        require("colorizer").setup({
            "css",
            "scss",
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "html",
            "!telescope",
            "!dashboard",
            "!NvimTree",
            "!lazy",
            "!git",
        }, {
            mode = "background",
            names = false,
            css = true,
            hsl_fn = true,
            css_fn = true,
        })
    end,
}
