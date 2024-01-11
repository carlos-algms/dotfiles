return {
    "klen/nvim-config-local",
    config = function()
        require("config-local").setup({
            -- Config file patterns to load (lua supported)
            config_files = { ".nvim.lua", ".nvimrc", ".exrc" },
        })
    end,
}
