return {
    "stevearc/oil.nvim",
    enabled = true,
    -- Optional dependencies
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },

    cmd = {
        "Oil",
    },

    keys = {
        {
            "-",
            "<cmd>Oil<CR>",
            desc = "Revel current file in Oil",
        },
    },

    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
        default_file_explorer = true,

        columns = {
            "icon",
            -- "permissions",
            -- "size",
            -- "mtime",
        },

        -- https://github.com/stevearc/oil.nvim?tab=readme-ov-file#options
        view_options = {
            show_hidden = true,
            case_insensitive = false,
        },

        keymaps = {
            ["q"] = "actions.close",
            ["<C-v>"] = {
                "actions.select",
                opts = { vertical = true, close = true },
                desc = "Open the entry in a vertical split",
            },
            ["<C-s>"] = {
                "actions.select",
                opts = { horizontal = true, close = true },
                desc = "Open the entry in a horizontal split",
            },
            ["<C-h>"] = false,
            ["<C-l>"] = false,
            ["R"] = "actions.refresh",
            ["`"] = false,
            ["~"] = false,
        },

        confirmation = {
            border = "rounded",
        },

        progress = {
            border = "rounded",
        },

        -- Configuration for the floating SSH window
        ssh = {
            border = "rounded",
        },

        -- Configuration for the floating keymaps help window
        keymaps_help = {
            border = "rounded",
        },
    },
}
