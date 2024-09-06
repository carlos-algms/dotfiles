-- https://github.com/nvim-lua/kickstart.nvim/blob/a22976111e406ec0e4903ae78bf66a1fc0125b8a/lua/kickstart/plugins/autopairs.lua
return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = { "hrsh7th/nvim-cmp" },
    config = function()
        require("nvim-autopairs").setup({})
        -- If you want to automatically add `(` after selecting a function or method
        local cmp_autoPairs = require("nvim-autopairs.completion.cmp")
        local cmp = require("cmp")
        cmp.event:on("confirm_done", cmp_autoPairs.on_confirm_done())
    end,
}
