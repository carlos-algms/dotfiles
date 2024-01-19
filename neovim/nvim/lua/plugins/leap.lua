return {
    "ggandor/leap.nvim",
    enabled = false,
    config = function()
        local leap = require("leap")
        leap.create_default_mappings()
    end,
}
