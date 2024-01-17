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
                icons_enabled = true,
                theme = "jellybeans",
            },
            sections = {
                lualine_a = {
                    {
                        "vim.fn.fnamemodify(vim.fn.getcwd(), ':t')",
                    },
                    {
                        "mode",
                        upper = true,
                    },
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
                    "encoding",
                    "fileformat",
                    "filetype",
                },
            },
        }

        require("lualine").setup(opts)
    end,
}
