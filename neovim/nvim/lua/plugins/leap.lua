return {
    "ggandor/leap.nvim",
    enabled = true,
    -- config = function()
    --     local leap = require("leap")
    --     leap.create_default_mappings()
    -- end,
    -- copy from https://www.lazyvim.org/extras/editor/leap
    keys = {
        { "s", mode = { "n", "x", "o" }, desc = "Leap forward to" },
        { "S", mode = { "n", "x", "o" }, desc = "Leap backward to" },
        { "gs", mode = { "n", "x", "o" }, desc = "Leap from windows" },
    },
    config = function(_, opts)
        local leap = require("leap")
        for k, v in pairs(opts) do
            leap.opts[k] = v
        end
        leap.add_default_mappings(true)
        vim.keymap.del({ "x", "o" }, "x")
        vim.keymap.del({ "x", "o" }, "X")

        -- Hack to hide cursor on auto jump
        vim.api.nvim_create_autocmd("User", {
            callback = function()
                vim.cmd.hi("Cursor", "blend=100")
                vim.opt.guicursor:append({ "a:Cursor/lCursor" })
            end,
            pattern = "LeapEnter",
        })

        vim.api.nvim_create_autocmd("User", {
            callback = function()
                vim.cmd.hi("Cursor", "blend=0")
                vim.opt.guicursor:remove({ "a:Cursor/lCursor" })
            end,
            pattern = "LeapLeave",
        })
    end,
}
