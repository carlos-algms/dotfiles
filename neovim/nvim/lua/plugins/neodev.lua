return {
    "folke/neodev.nvim",
    -- TODO: enable it only for the nvim folder
    -- enabled = false,
    -- add lazy here as wasn't initializing all the time
    lazy = false,
    config = function()
        require("neodev").setup({})
    end,
}
