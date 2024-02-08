return {
    -- "nvimdev/dashboard-nvim",
    -- dir = "~/projects/dashboard-nvim",
    "carlos-algms/dashboard-nvim",
    branch = "relative_paths_on_cwd_only",
    event = "VimEnter",
    dependencies = {
        { "nvim-tree/nvim-web-devicons" },
    },
    config = function()
        require("dashboard").setup({
            theme = "hyper",
            shortcut_type = "number",
            config = {
                week_header = {
                    enable = true,
                },
                shortcut = {
                    {
                        desc = "󰚰 Update",
                        group = "Function",
                        action = "Lazy update",
                        key = "U",
                    },
                    {
                        desc = " New file",
                        group = "Type",
                        action = "enew",
                        key = "n",
                    },
                    {
                        desc = "󰩈 Quit",
                        group = "Keyword",
                        action = "q",
                        key = "q",
                    },
                },
                footer = {
                    "",
                },
                project = {
                    enable = false,
                },
                mru = {
                    limit = 9, -- limit to 9, other 1 becomes too slow, as it will wait to see I press 0
                    cwd_only = true,
                },
            },
        })

        vim.cmd.hi("link DashboardHeader Type")
    end,
}
