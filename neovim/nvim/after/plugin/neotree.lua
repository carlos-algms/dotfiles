-- vim.g.loaded_netrw = 1
-- vim.g.loaded_netrwPlugin = 1

vim.keymap.set("n", "<C-n>", "::Neotree filesystem reveal left<CR>")
vim.keymap.set("n", "<SC-n>", ":Neotree toggle<CR>")

require("neo-tree").setup({
    filesystem = {
        filtered_items = {
            visible = false, -- when true, they will just be displayed differently than normal items
            hide_dotfiles = false,
            hide_gitignored = false,
        },
        nesting_rules = {},
        group_empty_dirs = false,
    },
})
