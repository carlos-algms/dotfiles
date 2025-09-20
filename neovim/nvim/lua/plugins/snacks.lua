local P = {
    ---@module 'snacks'
    ---@type snacks.picker.Last[]
    Snacks_picker_hist = {},
}

local M = {
    "folke/snacks.nvim",
    priority = 1010,
    lazy = false,

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
                    "Content is not an image",
                    -- ACP from Avante
                    "Spawning Claude Code process",
                    "ACP stderr: Error: The provided `old_string` does not appear in the file",
                    "ACP stderr: Progress",
                    "ACP stderr: Packages",
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

        indent = { enabled = false },

        gitbrowse = {
            what = "permalink",
            notify = false,

            config = function(opts, _defaults)
                -- it seems to be called twice, but I use it so little that I don't care, for now
                -- I had to add this, because the config doesen't merge array like objects
                table.insert(
                    opts.remote_patterns,
                    { "^%S+-github:(.+)%.git$", "https://github.com/%1" }
                )
            end,

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
                "avi",
                "avif",
                "bmp",
                "gif",
                "heic",
                "ico",
                "jpeg",
                "jpg",
                "mkv",
                "mov",
                "mp4",
                "pdf",
                "png",
                -- "svg",
                "tiff",
                "webm",
                "webp",
            },
            doc = {
                enabled = false,
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
                P.store_picker_in_history(picker)
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

        {
            "<C-p>",
            function()
                Snacks.picker.files({
                    hidden = true,
                })
            end,
            desc = "Find files by name in the current folder",
            silent = true,
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
            desc = "Find files by name in the current folder",
            silent = true,
        },

        {
            "<leader>O",
            function()
                Snacks.picker.recent({
                    title = "Recent files anywhere",
                })
            end,
            desc = "Find files by name anywhere",
            silent = true,
        },

        {
            "<leader>bo",
            function()
                Snacks.picker.buffers({
                    current = false,
                    unloaded = false,
                    matcher = {
                        history_bonus = true,
                        frecency = true,
                    },
                })
            end,
            desc = "List open buffers",
            silent = true,
        },

        {
            "<leader>/",
            function()
                Snacks.picker.lines()
            end,
            desc = "Fuzzy search in current file",
            silent = true,
        },

        {
            "<leader>gB",
            function()
                Snacks.picker.git_branches()
            end,
            desc = "List git branches",
            silent = true,
        },

        {
            "<leader>gl",
            function()
                Snacks.picker.git_status()
            end,
            desc = "List git status",
            silent = true,
        },

        {
            "<leader>sg",
            function()
                Snacks.picker.grep({
                    matcher = {
                        filename_bonus = true,
                        frecency = true,
                    },
                })
            end,
            desc = "Live Grep all files - Snacks",
            silent = true,
        },

        {
            "<leader>sg",
            function()
                Snacks.picker.grep_word()
            end,
            desc = "Live Grep all files - Snacks",
            silent = true,
            mode = { "v", "x" },
        },

        {
            "<leader>vh",
            function()
                Snacks.picker.help()
            end,
            desc = "Neovim Help - Snacks",
            silent = true,
        },

        {
            "<leader>vk",
            function()
                Snacks.picker.keymaps()
            end,
            desc = "Keymaps - Snacks",
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

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "markdown",
            callback = function(args)
                vim.keymap.set("n", "K", function()
                    Snacks.image.hover()
                end, {
                    buffer = args.buf,
                    desc = "Show image under cursor (Snacks)",
                })
            end,
        })
    end,
}

---@param picker snacks.picker.Last
local function make_history_item_text(picker)
    local source = picker.opts.source or "unknown source"
    local pattern = picker.filter.pattern or ""
    local search = picker.filter.search or ""
    local text = source .. " | " .. pattern .. " > " .. search
    return text
end

--- @param picker snacks.Picker
function P.store_picker_in_history(picker)
    -- I've to schedule  because on_close is called before `last` is set
    vim.schedule(function()
        local last = require("snacks.picker.core.picker").last

        if
            not last
            or not vim.tbl_contains({ -- allowed list, not block
                "grep",
                "grep_word",
                "lines",
            }, picker.opts.source)
        then
            return
        end

        local text = make_history_item_text(last)

        -- Remove the old picker if canse a new one with the same parameters is run
        for i, p in ipairs(P.Snacks_picker_hist) do
            local label = make_history_item_text(p)

            if label == text then
                table.remove(P.Snacks_picker_hist, i)
                break
            end
        end

        table.insert(P.Snacks_picker_hist, 1, last)

        if #P.Snacks_picker_hist >= 20 then
            table.remove(P.Snacks_picker_hist, 20)
        end
    end)
end

function P.history_picker()
    Snacks.picker.pick(
        ---@type snacks.picker.Config
        {
            source = "history_picker",
            finder = function()
                local items = {} ---@type snacks.picker.finder.Item[]

                for _, picker in ipairs(P.Snacks_picker_hist) do
                    local text = make_history_item_text(picker)

                    table.insert(items, {
                        data = { picker = picker },
                        text = text,
                    })
                end

                return items
            end,
            confirm = function(picker, item)
                picker:close()

                if not item then
                    return
                end

                require("snacks.picker.core.picker").last = item.data.picker
                Snacks.picker.resume()
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
