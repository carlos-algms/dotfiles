return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    -- disabled as it isn't as good as neo-tree
    enabled = false,
    lazy = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    init = function()
        -- disable netrw at the very start of your init.lua
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
    end,
    config = function()
        require("nvim-tree").setup({
            sort = {
                sorter = "case_sensitive",
            },
            view = {
                width = 45,
            },
            renderer = {
                group_empty = true,
            },
            filters = {
                dotfiles = true,
            },
            enable_diagnostics = false,
            sort_case_insensitive = true,
            window = {
                position = "left",
                width = 45,
            },

            nesting_rules = {},
        })

        vim.keymap.set(
            { "n", "i", "v", "x" },
            "<C-n>",
            ":NvimTreeFindFile<CR>",
            { desc = "Reveal current file in Nvim Tree ", silent = true }
        )
        vim.keymap.set(
            { "n", "i", "v", "x" },
            "<C-S-n>",
            ":NvimTreeToggle<CR>",
            { desc = "Toggle Nvim Tree ", silent = true }
        )
    end,
}
