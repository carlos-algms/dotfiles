local P = {}

local M = {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        opt = true,
    },
    config = function()
        local opts = {
            options = {
                -- show only 1 line at the bottom, so it never truncates the content
                globalstatus = true,
                icons_enabled = true,
                theme = "jellybeans",
                disabled_filetypes = {
                    statusline = {
                        -- "dapui_scopes",
                        -- "dapui_breakpoints",
                        -- "dapui_stacks",
                        -- "dapui_watches",
                        -- "dap-repl",
                        -- "dapui_console",
                        -- "neo-tree",
                    },
                    winbar = {
                        "DiffviewFiles",
                        -- "oil",
                        "neo-tree",
                        "dap-repl",
                        "fugitive",
                        "Avante",
                        "AvanteInput",
                        "AvanteSelectedFiles",
                        "AvanteTodos",
                        -- "trouble",
                        "quickfix",
                        "qf",
                        "DiffviewFileHistory",
                    },
                },
                refresh = {
                    statusline = 600,
                    tabline = 400,
                    winbar = 100,
                },
            },

            -- Winbar is one per window/split, and is only visible in he focused window
            -- so, depending to the width, the content will be truncated
            winbar = {
                lualine_b = {
                    {
                        P.buffer_name,
                        -- "filename",
                        -- path = 1,
                        separator = { left = " ", right = " " },
                    },
                },
            },
            inactive_winbar = {
                lualine_b = {
                    {
                        P.buffer_name,
                        -- "filename",
                        -- path = 1,
                        separator = { left = " ", right = " " },
                    },
                },
            },

            -- Tab line is one per Tab pane, at the top, no matter how many windows/splits are in it
            -- tabline = {
            --     lualine_a = {
            --         {
            --             "vim.fn.fnamemodify(vim.fn.getcwd(), ':t')",
            --         },
            --     },

            --     lualine_b = {
            --         "branch",
            --     },
            -- },

            sections = {
                lualine_a = {
                    {
                        "vim.fn.fnamemodify(vim.fn.getcwd(), ':t')",
                    },
                    -- {
                    --     "mode",
                    --     upper = true,
                    -- },
                },
                lualine_b = {
                    "branch",
                },
                lualine_c = {
                    -- {
                    --     "filename",
                    --     path = 1,
                    -- },
                },
                lualine_x = {
                    -- "encoding",
                    "fileformat",
                },
                lualine_y = {
                    "filetype",
                },
                lualine_z = {
                    "location",
                },
            },

            extensions = {
                -- "quickfix",
                -- "oil",
                -- "trouble",
                -- "neo-tree",
                -- "fugitive",
                -- "nvim-dap-ui",
            },
        }

        require("lualine").setup(opts)
    end,
}

local cache = require("helpers.cache")

local symbols = {
    modified = "",
    readonly = "",
    unnamed = "[No Name]",
    newfile = "",
    diff = "",
}

--- @type fun(path: string, self: table): { name: string, icon: string?, icon_highlight: string? }
local cachedBufferInfo = cache.cacheByKey("buffer_name", function(self)
    local devIcons = require("nvim-web-devicons")
    local highlight = require("lualine.highlight")
    local utils = require("lualine.utils.utils")

    local relativePath = vim.fn.expand("%:~:.")

    if relativePath == "" then
        return {
            name = symbols.unnamed,
            icon = nil,
            icon_highlight = nil,
        }
    end

    relativePath = relativePath:gsub("diffview://.*/%.git/.-/", "diffview://")
    relativePath = relativePath:gsub("fugitive://.*/%.git//", "fugitive:/")
    relativePath = relativePath:gsub("octo://.*/file/RIGHT/", "octo://NEW/")
    relativePath = relativePath:gsub("octo://.*/file/LEFT/", "octo://BASE/")
    relativePath = relativePath:gsub(".*%.fugitiveblame", "fugitive:Blame")

    local icon, icon_highlight_group = devIcons.get_icon(
        vim.fn.expand("%:~:t"),
        vim.fn.expand("#" .. vim.fn.bufnr("%") .. ":e")
    )

    --- @type string|nil
    local icon_highlight = nil

    if icon then
        if not self.icon_hl_cache then
            self.icon_hl_cache = {}
        end

        -- https://github.com/nvim-lualine/lualine.nvim/blob/2a5bae925481f999263d6f5ed8361baef8df4f83/lua/lualine/components/filetype.lua#L47
        local highlight_color =
            utils.extract_highlight_colors(icon_highlight_group, "fg")
        if highlight_color then
            icon_highlight = self.icon_hl_cache[highlight_color]
            if
                not icon_highlight
                or not highlight.highlight_exists(
                    icon_highlight.name .. "_normal"
                )
            then
                icon_highlight = self:create_hl(
                    { fg = highlight_color },
                    icon_highlight_group
                )
                self.icon_hl_cache[highlight_color] = icon_highlight
            end
        end
    end

    return {
        name = relativePath,
        icon = icon,
        icon_highlight = icon_highlight,
    }
end)

local function is_new_file()
    local filename = vim.fn.expand("%")
    return filename ~= ""
        and vim.bo.buftype == ""
        and vim.fn.filereadable(filename) == 0
end

function P.buffer_name(self)
    local bufferInfo = nil

    if vim.bo.filetype == "trouble" then
        return "󱖫 Trouble - "
            .. require("lualine.extensions.trouble").sections.lualine_a[1]()
    else
        local bufferPath = vim.fn.expand("%:~:p")
        bufferInfo = cachedBufferInfo(bufferPath, self)
    end

    local name, icon, icon_highlight =
        bufferInfo.name, bufferInfo.icon, bufferInfo.icon_highlight

    if icon then
        local default_highlight = self:get_default_hl()
        icon = self:format_hl(icon_highlight) .. icon .. default_highlight
        name = icon .. " " .. name
    end

    if vim.bo.modified then
        name = name .. " " .. symbols.modified
    end

    if vim.bo.readonly or vim.bo.modifiable == false then
        name = name .. " " .. symbols.readonly
    end

    if string.find(name, "diffview://") or string.find(name, "fugitive://") then
        name = name .. " " .. symbols.diff
    elseif is_new_file() and not string.find(name, "octo://") then
        name = name .. " " .. symbols.newfile
    end

    return name
end

return M
