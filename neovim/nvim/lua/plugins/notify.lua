return {
    "rcarriga/nvim-notify",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        local notify = require("notify")
        local banned_messages = { "No information available" }

        vim.notify = function(msg, ...)
            for _, banned in ipairs(banned_messages) do
                if msg == banned then
                    return
                end
            end
            return notify(msg, ...)
        end

        ---@diagnostic disable-next-line: missing-fields
        notify.setup({
            max_width = 80,
            render = "wrapped-compact",
        })
    end,
}
