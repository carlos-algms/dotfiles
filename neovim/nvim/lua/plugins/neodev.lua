return {
    "folke/neodev.nvim",
    -- TODO: enable it only for the nvim folder
    -- enabled = false,
    config = function()
        require("neodev").setup({})
    end,
}
