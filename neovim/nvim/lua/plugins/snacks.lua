local P = {
    Snacks_picker_hist = {},
}

local M = {
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

        bigfile = {
            enabled = true,
            size = 1.5 * 1024 * 1024, -- 1.5MB
            line_length = 300, -- average line length (useful for minified files)
        },

        notifier = {
            enabled = true,
            timeout = 6000,
            margin = { top = 1, right = 1, bottom = 0 },
            filter = function(notif)
                local patterns = {
                    -- LSP Hover was triggering this but it was working normally
                    "No information available",
                    -- triggered when Eslint isn't installed
                    "Unable to find ESLint library",
                    "eslint: -32603", -- no eslint config found
                    "Could not find config file",
                }

                for _, pattern in ipairs(patterns) do
                    if string.find(notif.msg, pattern) then
                        return false
                    end
                end
                return true
            end,
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

            win = {
                input = {
                    keys = {
                        ["<C-h>"] = { "toggle_help_list", mode = { "i", "n" } },
                    },
                },

                preview = {
                    keys = {
                        ["<CR>"] = "confirm",
                    },
                },
            },

            on_close = function(picker)
                if
                    not vim.tbl_contains(
                        { "history_picker", "lsp_references", "recent" },
                        picker.opts.source
                    )
                then
                    vim.schedule(function()
                        if #P.Snacks_picker_hist >= 20 then
                            table.remove(P.Snacks_picker_hist, 20)
                        end
                        table.insert(
                            P.Snacks_picker_hist,
                            1,
                            require("snacks.picker.core.picker").last
                        )
                    end)
                end
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
            desc = "Notification History with Snacks",
        },

        {
            "<leader>gy",
            function()
                Snacks.gitbrowse.open()
            end,
            mode = { "n", "v" },
            desc = "Copy git remote URL to clipboard with Snacks",
        },

        {
            "<leader>sr",
            function()
                Snacks.picker.resume()
            end,
            desc = "Resume last Snacks picker",
        },

        {
            "<leader>sp",
            function()
                P.history_picker()
            end,
            desc = "List Snacks pickers history",
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

function P.history_picker()
    Snacks.picker.pick(
        ---@type snacks.picker.Config
        {
            source = "history_picker",
            finder = function()
                local items = {} ---@type snacks.picker.finder.Item[]

                for _, picker in ipairs(P.Snacks_picker_hist) do
                    local source = picker.opts.source or "unknown source"
                    local pattern = picker.filter.pattern or ""
                    local search = picker.filter.search or ""
                    local text = source .. " | " .. pattern .. " > " .. search
                    table.insert(items, {
                        ["data"] = { picker = picker },
                        text = text,
                    })
                end

                return items
            end,
            confirm = function(picker, item)
                picker:close()
                if item then
                    require("snacks.picker.core.picker").last = item.data.picker
                    Snacks.picker.resume()
                end
            end,
            format = function(item, _)
                local ret = {}
                ret[#ret + 1] = { item.text }
                return ret
            end,
            layout = {
                layout = {
                    backdrop = {
                        blend = 40,
                    },
                    width = 0.3,
                    min_width = 80,
                    max_height = 12,
                    box = "vertical",
                    border = "rounded",
                    title = " Picker history ",
                    title_pos = "center",
                    { win = "list", border = "none" },
                    { win = "input", height = 1, border = "top" },
                },
            },
        }
    )
end

return M
