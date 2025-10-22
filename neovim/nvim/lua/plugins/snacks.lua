local P = {
    ---@module 'snacks'
    ---@type snacks.picker.resume.State[]
    Snacks_picker_hist = {},
}

--- Remember to deep copy before use
--- @type snacks.picker.grep.Config
local customGrepOptions = {
    hidden = true,
    live = true,
    regex = false, -- defualt to false, I search form [, {, -, etc too often, <A-r> to toggle it
    matcher = {
        filename_bonus = true,
        frecency = true,
    },
    args = {
        "-g",
        "!pnpm-lock.yaml",
        "-g",
        "!pnpm-workspace.yaml",
        "-g",
        "!yarn.lock",
        "-g",
        "!package-lock.json",
        "-g",
        "!node_modules/",
    },
}

local M = {
    -- dir = vim.uv.os_homedir() .. "/projects/snacks-nvim",
    -- dev = true,
    -- name = "snacks.nvim",
    "folke/snacks.nvim",
    priority = 1010,
    lazy = false,

    opts = function()
        local resume = require("snacks.picker.resume")
        local original_add = resume.add

        ---@diagnostic disable-next-line: duplicate-set-field
        resume.add = function(picker)
            original_add(picker)
            local source = picker.opts.source or "custom"
            local state = resume.state[source]
            if not state then
                return
            end
            P.store_picker_in_history(state)
        end

        ---@type snacks.Config
        local opts = {
            input = {
                enabled = true,
                relative = "cursor",
            },

            bufdelete = {
                enabled = true,
            },

            bigfile = {
                enabled = true,
                size = 3 * 1024 * 1024,
                line_length = 600, -- average line length (useful for minified files)
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
                    -- I had to add this, because the config doesn't merge array like objects
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

                actions = {
                    add_iglob = function(picker)
                        local search = picker.input.filter.search
                        local prefix = ""

                        if not string.find(search, " %-%- ") then
                            prefix = " -- "
                        end

                        picker.input:set(nil, search .. prefix .. " --iglob ")
                    end,

                    exclude_test_files = function(picker)
                        local search = picker.input.filter.search
                        local prefix = ""

                        if not string.find(search, " %-%- ") then
                            prefix = " -- "
                        end

                        picker.input:set(
                            nil,
                            search .. prefix .. " --iglob !**.{test,spec}.**"
                        )
                    end,
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
                            ["<a-r>"] = { -- not docummented, but works
                                "toggle_regex",
                                mode = { "i", "n" },
                                desc = "Toggle Regex",
                            },
                            ["<C-h>"] = {
                                "toggle_help_input",
                                mode = { "i", "n" },
                            },
                            ["<C-l>"] = { "add_iglob", mode = { "i", "n" } },
                            ["<C-e>"] = {
                                "exclude_test_files",
                                mode = { "i", "n" },
                            },
                        },
                    },

                    preview = {
                        keys = {
                            ["<CR>"] = "confirm",
                        },
                    },
                },
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
        }

        return opts
    end,

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
        },

        {
            "<leader>O",
            function()
                Snacks.picker.recent({
                    title = "Recent files anywhere",
                })
            end,
            desc = "Find files by name anywhere",
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
        },

        {
            "<leader>/",
            function()
                Snacks.picker.lines()
            end,
            desc = "Fuzzy search in current file",
        },

        {
            "<leader>gB",
            function()
                Snacks.picker.git_branches()
            end,
            desc = "List git branches",
        },

        {
            "<leader>gl",
            function()
                Snacks.picker.git_status()
            end,
            desc = "List git status",
        },

        {
            "<leader>f",
            function()
                Snacks.picker.grep(
                    vim.tbl_deep_extend("force", {}, customGrepOptions)
                )
            end,
            desc = "Live Grep all files - Snacks",
        },

        {
            "<leader>f",
            function()
                Snacks.picker.grep_word(
                    vim.tbl_deep_extend("force", {}, customGrepOptions)
                )
            end,
            desc = "Live Grep all files - Snacks",
            mode = { "v", "x" },
        },

        {
            "<leader>vh",
            function()
                Snacks.picker.help()
            end,
            desc = "Neovim Help - Snacks",
        },

        {
            "<leader>vk",
            function()
                Snacks.picker.keymaps()
            end,
            desc = "Keymaps - Snacks",
        },

        {
            "<leader>sd",
            function()
                P.grep_on_dir()
            end,
            desc = "Grep on directory - Snacks",
        },

        {
            "gd",
            function()
                local current_word = vim.fn.expand("<cword>")
                Snacks.picker.lsp_definitions({
                    title = string.format("LSP Definitions `%s`", current_word),
                })
            end,
            desc = "Go to definition or list all - Snacks",
            mode = { "n", "v" },
        },

        {
            "gr",
            function()
                local current_word = vim.fn.expand("<cword>")
                Snacks.picker.lsp_references({
                    title = string.format("LSP References `%s`", current_word),
                })
            end,
            desc = "Go to reference or list all - Snacks",
            mode = { "n", "v" },
        },

        {
            "gi",
            function()
                local current_word = vim.fn.expand("<cword>")
                Snacks.picker.lsp_implementations({
                    title = string.format(
                        "LSP Implementations `%s`",
                        current_word
                    ),
                })
            end,
            desc = "Go to implementation or list all - Snacks",
            mode = { "n", "v" },
        },

        {
            "gD",
            function()
                local current_word = vim.fn.expand("<cword>")
                Snacks.picker.lsp_declarations({
                    title = string.format(
                        "LSP Declarations `%s`",
                        current_word
                    ),
                })
            end,
            desc = "Go to declaration or list all - Snacks",
            mode = { "n", "v" },
        },

        {
            "go",
            function()
                local current_word = vim.fn.expand("<cword>")
                Snacks.picker.lsp_type_definitions({
                    title = string.format(
                        "LSP Type Definitions `%s`",
                        current_word
                    ),
                })
            end,
            desc = "Go to type definition or list all - Snacks",
            mode = { "n", "v" },
        },

        {
            "gO",
            function()
                Snacks.picker.lsp_symbols()
            end,
            desc = "Search for symbol in document - Snacks",
        },

        {
            "gW",
            function()
                Snacks.picker.lsp_workspace_symbols()
            end,
            desc = "Search for symbol in workspace - Snacks",
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

                -- Override print to use snacks for `:=` command
                if vim.fn.has("nvim-0.11") == 1 then
                    vim._print = function(_, ...)
                        dd(...)
                    end
                else
                    vim.print = _G.dd
                end
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

---@param state snacks.picker.resume.State
local function make_history_item_text(state)
    local prefix = state.opts.title or state.opts.source or "unknown source"
    local pattern = state.filter.pattern or ""
    local search = state.filter.search or ""
    local text = prefix .. " | " .. pattern .. " > " .. search
    return text
end

--- First, Show a picker to select directories
--- Then, Show the Grep picker focused on the selected directories only
function P.grep_on_dir()
    Snacks.picker.pick({
        source = "dir_picker_for_grep",
        layout = {
            preset = "select",
            cycle = true,
        },

        finder = function()
            local items = {} ---@type snacks.picker.finder.Item[]

            local cmd = { "fd", "-t", "d" }
            local result = vim.fn.systemlist(cmd)

            if vim.v.shell_error ~= 0 then
                Snacks.notify.error("Failed to run fd command", {
                    title = "Grep on Directory",
                })
                return items
            end

            for _, dir in ipairs(result) do
                table.insert(items, {
                    data = { dir = dir },
                    text = dir,
                })
            end

            return items
        end,

        confirm = function(picker)
            picker:close()

            local items = picker:selected({ fallback = true })

            if not items or #items == 0 then
                return
            end

            local dirs = {}
            for _, item in ipairs(items) do
                table.insert(dirs, item.data.dir)
            end

            Snacks.picker.grep(
                vim.tbl_deep_extend("force", {}, customGrepOptions, {
                    dirs = dirs,
                    title = "Grep in: " .. table.concat(dirs, ", "),
                })
            )
        end,

        format = function(item, _)
            local ret = {
                { item.text },
            }
            return ret
        end,
    })
end

--- @param state snacks.picker.resume.State
function P.store_picker_in_history(state)
    local source = state.opts.source
    if
        source
        and not source:find("^lsp_")
        and not vim.tbl_contains({
            -- allowed list, not block
            "grep",
            "grep_word",
            "lines",
        }, source)
    then
        return
    end

    local text = make_history_item_text(state)

    -- Remove the old picker if canse a new one with the same parameters is run
    for i, p in ipairs(P.Snacks_picker_hist) do
        local label = make_history_item_text(p)

        if label == text then
            table.remove(P.Snacks_picker_hist, i)
            break
        end
    end

    table.insert(P.Snacks_picker_hist, 1, state)

    if #P.Snacks_picker_hist >= 20 then
        table.remove(P.Snacks_picker_hist, 20)
    end
end

function P.history_picker()
    Snacks.picker.pick(
        ---@type snacks.picker.Config
        {
            source = "history_picker",
            finder = function()
                local items = {} ---@type snacks.picker.finder.Item[]

                for _, state in ipairs(P.Snacks_picker_hist) do
                    local text = make_history_item_text(state)

                    table.insert(items, {
                        data = { state = state },
                        text = text,
                    })
                end

                return items
            end,
            confirm = function(historyPicker, item)
                historyPicker:close()

                if not item then
                    return
                end

                vim.schedule(function()
                    local resume = require("snacks.picker.resume")
                    resume._resume(item.data.state)
                end)
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
