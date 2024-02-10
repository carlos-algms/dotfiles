return {
    "j-hui/fidget.nvim",
    enabled = true,
    config = function()
        require("fidget").setup({
            progress = {
                ignore = { "null-ls" },
            },
        })
    end,
}
