return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    dependencies = {
        "ggandor/leap.nvim", -- add as dependency to try to avoid keymaps conflicts
    },
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
    end,
    opts = {},
}
