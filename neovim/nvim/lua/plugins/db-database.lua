return {
    {
        "kristijanhusak/vim-dadbod-ui",

        dependencies = {
            { "tpope/vim-dadbod" },
            {
                "kristijanhusak/vim-dadbod-completion",
                ft = { "sql", "mysql", "plsql" },
            },
        },
        cmd = {
            "DBUI",
            "DBUIToggle",
            "DBUIAddConnection",
            "DBUIFindBuffer",
        },

        init = function()
            vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db-ui"
            vim.g.db_ui_use_nerd_fonts = 1
            vim.g.db_ui_auto_execute_table_helpers = 0
            vim.g.db_ui_disable_mappings_javascript = 1
            vim.g.db_ui_table_helpers = {
                { name = "Select", query = "SELECT * FROM {{table}}" },
                { name = "Insert", query = "INSERT INTO {{table}} VALUES ()" },
                {
                    name = "Update",
                    query = "UPDATE {{table}} SET {{column}} = '' WHERE id = ''",
                },
                {
                    name = "Delete",
                    query = "DELETE FROM {{table}} WHERE id = ''",
                },
            }
        end,
    },
    -- Disabled it was crashing with "out of memory" error
    -- {
    --     "kndndrj/nvim-dbee",
    --     dependencies = {
    --         "MunifTanjim/nui.nvim",
    --     },
    --     build = function()
    --         -- Install tries to automatically detect the install method.
    --         -- if it fails, try calling it with one of these parameters:
    --         --    "curl", "wget", "bitsadmin", "go"
    --         require("dbee").install()
    --     end,
    --     config = function()
    --         require("dbee").setup()
    --     end,
    -- },
}
