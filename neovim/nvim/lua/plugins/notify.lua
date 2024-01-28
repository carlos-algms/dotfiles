return {
    "rcarriga/nvim-notify",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        local notify = require("notify")
        vim.notify = notify

        ---@diagnostic disable-next-line: missing-fields
        notify.setup({
            max_width = 80,
        })
    end,
}
