-- https://github.com/nvim-lua/kickstart.nvim/blob/a22976111e406ec0e4903ae78bf66a1fc0125b8a/lua/kickstart/plugins/autopairs.lua
return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
        require("nvim-autopairs").setup({})
    end,
}
