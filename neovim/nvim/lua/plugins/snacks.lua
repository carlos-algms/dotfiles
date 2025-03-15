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

        scroll = { enabled = false },

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

        image = {
            enabled = true,
            formats = {
                "png",
                "jpg",
                "jpeg",
                "gif",
                "bmp",
                "webp",
                "tiff",
                "heic",
                "avif",
                "mp4",
                "mov",
                "avi",
                "mkv",
                "webm",
                "pdf",
                "svg",
            },
            doc = {
                enabled = true,
                inline = false,
                float = true,
            },
        },

        picker = {
            ui_select = true, -- replace `vim.ui.select` with the snacks picker
            matcher = {
                fuzzy = true,
                smartcase = true,
                frecency = false,
                history_bonus = false,
            },
            layouts = {
                default = {
                    layout = {
                        box = "horizontal",
                        width = 0.97,
                        min_width = 120,
                        height = 0.9,
                        {
                            box = "vertical",
                            border = "rounded",
                            title = "{title} {live} {flags}",
                            {
                                win = "input",
                                height = 1,
                                border = "bottom",
                            },
                            { win = "list", border = "none" },
                        },
                        {
                            win = "preview",
                            title = "{preview:Preview}",
                            border = "rounded",
                            width = 0.55,
                        },
                    },
                },
            },

            previewers = {
                file = {
                    max_size = 1024 * 1024 * 5,
                },
            },

            on_close = function()
                -- TODO: implement pickers history
                -- https://github.com/WizardStark/dotfiles/blob/7749c9ff8f32e9c466ba58fa69966f0a3c5f5739/home/.config/nvim/lua/workspaces/ui.lua#L417
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

        {
            "<leader>sr",
            function()
                Snacks.picker.resume()
            end,
            desc = "Resume last picker",
        },
        {
            "<C-p>",
            function()
                Snacks.picker.smart()
            end,
            desc = "Pick files",
        },

        {
            "<leader>o",
            function()
                Snacks.picker.recent({
                    filter = {
                        cwd = vim.fn.getcwd(),
                    },
                })
            end,
            desc = "Old files",
        },

        {
            "<leader>O",
            function()
                Snacks.picker.recent()
            end,
            desc = "Old files everywhere",
        },

        {

            "<leader>f",
            function()
                Snacks.picker.grep()
            end,
            desc = "Live Grep",
            silent = true,
        },

        {

            "<leader>f",
            function()
                Snacks.picker.grep_word()
            end,
            desc = "Live Grep selection",
            silent = true,
            mode = { "v" },
        },

        {
            "gd",
            function()
                Snacks.picker.lsp_definitions()
            end,
            desc = "Goto Definition",
        },

        {
            "gD",
            function()
                Snacks.picker.lsp_declarations()
            end,
            desc = "Goto Declaration",
        },

        {
            "gr",
            function()
                Snacks.picker.lsp_references()
            end,
            desc = "LSP References",
        },

        {
            "gi",
            function()
                Snacks.picker.lsp_implementations()
            end,
            desc = "Goto Implementation",
        },

        {
            "go",
            function()
                Snacks.picker.lsp_type_definitions()
            end,
            desc = "Goto Type Definition",
        },

        {
            "<leader>rw",
            function()
                Snacks.picker.lsp_workspace_symbols()
            end,
            desc = "LSP Workspace Symbols",
        },

        {
            "<leader>rd",
            function()
                Snacks.picker.lsp_symbols()
            end,
            desc = "LSP Document Symbols",
        },

        {
            "<leader>tt",
            function()
                Snacks.picker.todo_comments({
                    keywords = { "FIXIT" },
                })
            end,
            desc = "FIXIT Comments",
            silent = true,
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
