return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        opt = true,
    },
    config = function()
        -- local noice = require("noice")

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
                        "neo-tree",
                    },
                },
            },

            -- Winbar is one per window/split, and is only visible int he focused window
            -- so, depnding to the width, the content will be truncated
            -- winbar = {}

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
                    {
                        "filename",
                        path = 1,
                    },
                },
                lualine_x = {
                    -- {
                    --     noice.api.status.mode.get,
                    --     cond = noice.api.status.mode.has,
                    --     color = { fg = "#ff9e64" },
                    -- },
                    -- "encoding",
                    "fileformat",
                },
                lualine_y = {
                    "filetype",
                },
                lualine_z = {
                    -- "location",
                },
            },
        }

        require("lualine").setup(opts)
    end,
}
