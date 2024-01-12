-- vim.g.loaded_netrw = 1
-- vim.g.loaded_netrwPlugin = 1

return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
        -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    init = function()
        if vim.fn.argc(-1) == 1 then
            local stat = vim.loop.fs_stat(vim.fn.argv(0))
            if stat and stat.type == "directory" then
                require("neo-tree")
            end
        end
    end,
    opts = {
        sources = { "filesystem", "buffers", "git_status", "document_symbols" },
        filesystem = {
            filtered_items = {
                visible = true, -- when true, they will just be displayed differently than normal items
                hide_dotfiles = false,
                hide_gitignored = false,
            },
            nesting_rules = {},
            group_empty_dirs = false,
        },
        -- nesting_rules = {
        --     ["js"] = {
        --         pattern = "(.+)%.js$",
        --         files = { "%1.js.map", "%1.min.js", "%1.d.ts" },
        --     },
        --     ["ts"] = {
        --         pattern = "(.+)%.ts$",
        --         files = { "%1.*.ts", "%1.*.css" },
        --     },
        --     ["tsx"] = {
        --         pattern = "(.+)%.tsx$",
        --         files = {
        --             "%1.*.ts",
        --             "%1.*.tsx",
        --             "%1.*.ts",
        --             "%1.*.ts*",
        --             "%1.*.css",
        --             "%1.*.scss",
        --             "%1.*.mdx",
        --             "%1.*.mdx",
        --         },
        --     },
        -- },
    },
    config = function(_, opts)
        vim.keymap.set(
            "n",
            "<C-n>",
            "::Neotree filesystem reveal left<CR>",
            { desc = "Reveal current file in NeoTree ", silent = true }
        )
        vim.keymap.set(
            "n",
            "<SC-n>",
            ":Neotree toggle<CR>",
            { desc = "Toggle NeoTree ", silent = true }
        )

        -- require("neo-tree").setup({
        --     filesystem = {
        --         filtered_items = {
        --             visible = false, -- when true, they will just be displayed differently than normal items
        --             hide_dotfiles = false,
        --             hide_gitignored = false,
        --         },
        --         nesting_rules = {},
        --         group_empty_dirs = false,
        --     },
        -- })
        require("neo-tree").setup(opts)
    end,
}
