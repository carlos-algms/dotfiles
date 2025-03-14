return {
    "folke/snacks.nvim",
    priority = 1010,
    lazy = false,

    ---@module 'snacks'
    ---@type snacks.Config
    opts = {
        input = {
            enabled = true,
            relative = "cursor",
        },
        notifier = {
            enabled = true,
            margin = { top = 1, right = 1, bottom = 0 },
        },
        scroll = { enabled = true },
        statuscolumn = { enabled = true },
        indent = { enabled = true },
        gitbrowse = {
            what = "permalink",
            notify = false,
            open = function(url)
                vim.fn.setreg("+", url)
                Snacks.notify.info("Link copied to clipboard:\n" .. url, {
                    title = "Snacks - GitBrowse",
                    icon = "🔗 ",
                    timeout = 5000,
                })
            end,
        },

        styles = {
            input = {
                relative = "cursor",
                row = -3,
                col = 0,
            },
            notification = {
                relative = "editor",
                wo = {
                    wrap = true,
                },
            },
            notification_history = {
                relative = "editor",
                wo = {
                    wrap = true,
                },
            },
        },
    },
    keys = {
        {
            "<leader>vn",
            function()
                Snacks.notifier.show_history()
            end,
            desc = "Notification History",
        },
        {
            "<leader>gy",
            function()
                Snacks.gitbrowse.open()
            end,
            mode = { "n", "v" },
            desc = "Copy git remote URL to clipboard",
        },
    },
    init = function()
        vim.api.nvim_create_autocmd("User", {
            pattern = "VeryLazy",
            callback = function()
                -- Setup some globals for debugging (lazy-loaded)
                _G.dd = function(...)
                    Snacks.debug.inspect(...)
                end
                _G.bt = function()
                    Snacks.debug.backtrace()
                end
                vim.print = _G.dd -- Override print to use snacks for `:=` command
            end,
        })
    end,
}
