return {
    -- "klen/nvim-config-local",
    "mrjohannchang/nvim-config-local", -- the original seems to be abandoned
    lazy = false,
    version = "df334bb", -- fixing a specific hash to avoid exploits or malicious new code
    config = function()
        require("config-local").setup({
            -- Config file patterns to load (lua supported)
            config_files = { ".nvim.lua", ".nvimrc", ".exrc" },
            -- I enabled it in case I open a nested directory inside a big project
            lookup_parents = true, -- Lookup config files in parent directories
        })
    end,
}
