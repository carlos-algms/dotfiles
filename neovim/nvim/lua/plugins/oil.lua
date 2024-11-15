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
            ["<C-x>"] = {
                "actions.select",
                opts = { horizontal = true, close = true },
                desc = "Open the entry in a horizontal split",
            },
            -- Disabled to avoid mistyping
            ["<C-s>"] = false,
            ["<C-h>"] = false,
            ["_"] = false,
            ["`"] = false,
            ["~"] = false,
        },
    },
    config = function(_, opts)
        require("oil").setup(opts)
    end,
}
