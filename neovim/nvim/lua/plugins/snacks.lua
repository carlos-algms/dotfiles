vim.pack.add({
    "https://github.com/folke/snacks.nvim",
})

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

        config = function(o, _defaults)
            -- it seems to be called twice, but I use it so little that I don't care, for now
            -- I had to add this, because the config doesn't merge array like objects
            vim.list_extend(o.remote_patterns, {
                { "^%S+-github:(.+)%.git$", "https://github.com/%1" },
                { "^%S+-github:(.+)$", "https://github.com/%1" },
            })
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

    scratch = {
        filekey = {
            branch = false,
        },
        win = {
            keys = {
                new_scratch = {
                    "<localLeader>n",
                    function(self)
                        self:close()
                        vim.schedule(function()
                            Snacks.scratch.open()
                        end)
                    end,
                    mode = { "n" },
                    desc = "New Scratch Buffer",
                },
            },
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
                    ["<a-r>"] = { -- not documented, but works
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

        sources = {
            scratch = {
                win = {
                    input = {
                        keys = {
                            ["<c-n>"] = {
                                "list_down",
                                mode = { "i", "n" },
                            },
                        },
                    },
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
        scratch = {
            width = 0.8,
            height = 0.6,
            wo = {
                wrap = true,
            },
        },
    },
}

require("snacks").setup(opts)

-- Debug globals and print override (was in lazy.nvim `init`)
-- Setup some globals for debugging (lazy-loaded)
_G.dd = function(...)
    Snacks.debug.inspect(...)
end
_G.bt = function()
    Snacks.debug.backtrace()
end

-- Override print to use snacks for `:=` command
if vim.fn.has("nvim-0.11") == 1 then
    ---@diagnostic disable-next-line: duplicate-set-field
    vim._print = function(_, ...)
        dd(...)
    end
else
    vim.print = _G.dd
end

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

-- Keymaps
local set = vim.keymap.set
local nv = { "n", "v" }

local function lsp_pick(method, label)
    return function()
        local word = vim.fn.expand("<cword>")
        Snacks.picker[method]({
            title = string.format("LSP %s `%s`", label, word),
        })
    end
end

local function grep_opts(extra)
    return vim.tbl_deep_extend("force", {}, customGrepOptions, extra or {})
end

set("n", "<leader>vn", function() Snacks.notifier.show_history() end, { desc = "Notification History with Snacks" })
set(nv, "<leader>gy", function() Snacks.gitbrowse.open() end, { desc = "Copy git remote URL to clipboard with Snacks" })
set("n", "<leader>sr", function() Snacks.picker.resume() end, { desc = "Resume last Snacks picker" })
set("n", "<leader>sh", function() P.history_picker() end, { desc = "List Snacks pickers history" })
set("n", "<C-p>", function() Snacks.picker.files({ hidden = true }) end, { desc = "Find files by name in the current folder" })
set("n", "<leader>o", function() Snacks.picker.recent({ filter = { cwd = vim.fn.getcwd() } }) end, { desc = "Find files by name in the current folder" })
set("n", "<leader>O", function() Snacks.picker.recent({ title = "Recent files anywhere" }) end, { desc = "Find files by name anywhere" })
set("n", "<leader>bo", function() Snacks.picker.buffers({ current = false, unloaded = false, matcher = { history_bonus = true, frecency = true } }) end, { desc = "List open buffers" })
set("n", "<leader>/", function() Snacks.picker.lines() end, { desc = "Fuzzy search in current file" })
set("n", "<leader>gB", function() Snacks.picker.git_branches() end, { desc = "List git branches" })
set("n", "<leader>gl", function() Snacks.picker.git_status() end, { desc = "List git status" })
set("n", "<leader>f", function() Snacks.picker.grep(grep_opts()) end, { desc = "Live Grep all files - Snacks" })
set({ "v", "x" }, "<leader>f", function() Snacks.picker.grep_word(grep_opts()) end, { desc = "Live Grep all files - Snacks" })
set("n", "<leader>vh", function() Snacks.picker.help() end, { desc = "Neovim Help - Snacks" })
set("n", "<leader>vk", function() Snacks.picker.keymaps() end, { desc = "Keymaps - Snacks" })
set("n", "<leader>sd", function() P.grep_on_dir() end, { desc = "Grep on directory - Snacks" })

set(nv, "gd", lsp_pick("lsp_definitions", "Definitions"), { desc = "Go to definition or list all - Snacks" })
set(nv, "grr", lsp_pick("lsp_references", "References"), { desc = "Go to reference or list all - Snacks" })
set(nv, "gi", lsp_pick("lsp_implementations", "Implementations"), { desc = "Go to implementation or list all - Snacks" })
set(nv, "gD", lsp_pick("lsp_declarations", "Declarations"), { desc = "Go to declaration or list all - Snacks" })
set(nv, "go", lsp_pick("lsp_type_definitions", "Type Definitions"), { desc = "Go to type definition or list all - Snacks" })
set("n", "gO", function() Snacks.picker.lsp_symbols({ title = string.format("LSP Document Symbols `%s`", vim.fn.expand("%:t")) }) end, { desc = "LSP Document Symbols - Snacks" })
set("n", "gW", function() Snacks.picker.lsp_workspace_symbols() end, { desc = "LSP Workspace Symbols - Snacks" })

set("n", "<leader>cm", function() P.file_type_picker() end, { desc = "Change current buffer filetype - Snacks" })
set("n", "<leader>zo", function() Snacks.scratch({ filekey = { branch = false, count = false } }) end, { desc = "Toggle Scratch Buffer" })
set("n", "<leader>zl", function() Snacks.scratch.select() end, { desc = "Select Scratch Buffer" })
set("n", "<leader>zf", function() Snacks.picker.grep(grep_opts({ cwd = os.getenv("SECOND_BRAIN_PATH") })) end, { desc = "Second brain grep - Snacks" })
set("n", "<leader>zp", function() Snacks.picker.files({ hidden = false, cwd = os.getenv("SECOND_BRAIN_PATH") }) end, { desc = "Second brain files - Snacks" })
set("n", "<leader>zn", function() vim.cmd(string.format("e %s/%s.md", os.getenv("SECOND_BRAIN_PATH"), os.date("%Y-%m-%d_%H-%M"))) end, { desc = "Second brain new file - Snacks" })

-- Helper functions

---@param state snacks.picker.resume.State
local function make_history_item_text(state)
    local prefix = state.opts.title or state.opts.source or "custom"
    local pattern = state.filter.pattern or ""
    local search = state.filter.search or ""

    local text = prefix .. " | " .. search .. " > " .. pattern
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

    -- Remove the old picker in case a new one with the same title is added
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

                for i, state in ipairs(P.Snacks_picker_hist) do
                    local text = make_history_item_text(state)

                    table.insert(items, {
                        data = { state = state },
                        text = string.format("%s. %s", i, text),
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
                    local r = require("snacks.picker.resume")
                    r._resume(item.data.state)
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

function P.file_type_picker()
    Snacks.picker.pick(
        ---@type snacks.picker.Config
        {
            source = "history_picker",
            finder = function()
                local items = {} ---@type snacks.picker.finder.Item[]
                local filetypes = vim.fn.getcompletion("", "filetype")

                for _, text in ipairs(filetypes) do
                    table.insert(items, {
                        data = text,
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
                    vim.bo.filetype = item.data
                end)
            end,
            format = function(item, _)
                local ret = {}
                ret[#ret + 1] = { item.text }
                return ret
            end,
            layout = {
                preset = "select",
            },
        }
    )
end
