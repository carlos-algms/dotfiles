return {
    "norcalli/nvim-colorizer.lua",
    enabled = true,
    event = "VeryLazy",
    config = function()
        require("colorizer").setup({
            "*",
            "!telescope",
            "!dashboard",
            "!NvimTree",
            "!lazy",
            "!git",
        })
    end,
}
