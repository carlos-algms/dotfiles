return {
    "j-hui/fidget.nvim",
    enabled = true,
    -- lazy = true,
    config = function()
        require("fidget").setup({
            progress = {
                ignore = { "null-ls" },
            },
        })
    end,
}
