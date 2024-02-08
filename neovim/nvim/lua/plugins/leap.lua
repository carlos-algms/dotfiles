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
    end,
}
