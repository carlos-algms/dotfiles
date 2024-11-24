return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        opt = true,
    },
    config = function()
        local devIcons = require("nvim-web-devicons")
        local highlight = require("lualine.highlight")
        local utils = require("lualine.utils.utils")

        local function buffer_name(self)
            local relativePath = vim.fn.expand("%:~:.")

            if relativePath == "" then
                return "[No Name]"
            end

            local pathToRemove = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
                .. ".git/:0:/"

            relativePath = relativePath:gsub(pathToRemove, "")

            local icon, icon_highlight_group = devIcons.get_icon(
                vim.fn.expand("%:~:t"),
                vim.fn.expand("#" .. vim.fn.bufnr("%") .. ":e")
            )

            if icon then
                if not self.icon_hl_cache then
                    self.icon_hl_cache = {}
                end

                -- https://github.com/nvim-lualine/lualine.nvim/blob/2a5bae925481f999263d6f5ed8361baef8df4f83/lua/lualine/components/filetype.lua#L47
                local highlight_color =
                    utils.extract_highlight_colors(icon_highlight_group, "fg")
                if highlight_color then
                    local default_highlight = self:get_default_hl()

                    local icon_highlight = self.icon_hl_cache[highlight_color]
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

                    icon = self:format_hl(icon_highlight)
                        .. icon
                        .. default_highlight
                end

                return icon .. " " .. relativePath
            end

            return relativePath
        end

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
                    },
                },
            },

            -- Winbar is one per window/split, and is only visible in he focused window
            -- so, depending to the width, the content will be truncated
            winbar = {
                lualine_b = {
                    {
                        buffer_name,
                        -- "filename",
                        -- path = 1,
                        separator = { left = " ", right = " " },
                    },
                },
            },
            inactive_winbar = {
                lualine_b = {
                    {
                        buffer_name,
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
        }

        require("lualine").setup(opts)
    end,
}
