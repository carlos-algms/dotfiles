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
            "<C-n>",
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
        },
        keymaps = {
            ["q"] = "actions.close",
        },
    },
    config = function(_, opts)
        require("oil").setup(opts)
    end,
}
