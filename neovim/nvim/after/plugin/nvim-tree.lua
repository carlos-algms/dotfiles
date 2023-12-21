vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

require("nvim-tree").setup({
    sort_by = "case_sensitive",
    view = {
        width = 30,
    },
    renderer = {
        group_empty = true,
    },
    filters = {
        dotfiles = true,
    },
    on_attach = function(bufnr)
        local api = require("nvim-tree.api")

        local function opts(desc)
            return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        -- default mappings
        api.config.mappings.default_on_attach(bufnr)

        -- vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>')
        vim.keymap.set("n", "?", api.tree.toggle_help, opts("Help"))
    end,
})

vim.keymap.set("n", "<C-n>", ":NvimTreeFindFile<CR>")
vim.keymap.set("n", "<SC-n>", ":NvimTreeToggle<CR>")
