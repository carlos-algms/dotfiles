return {
    "rcarriga/nvim-notify",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        vim.notify = require("notify")
    end,
}
