return {
    {
        "yetone/avante.nvim",
        enabled = not vim.g.is_ssh,
        event = "VeryLazy",
        lazy = false,
        version = false, -- set this if you want to always pull the latest change
        keys = {
            {
                "<Leader>A",
                "",
                desc = "Avante",
                silent = true,
            },
            {
                "<Leader>Aa",
                function()
                    require("avante.api").ask()
                end,
                desc = "Avante Ask",
                silent = true,
            },
            {
                "<Leader>Ae",
                function()
                    require("avante.api").edit()
                end,
                desc = "Avante Edit",
                silent = true,
            },
            {
                "<Leader>Ar",
                function()
                    require("avante.api").refresh()
                end,
                desc = "Avante Refresh",
                silent = true,
            },
            {
                "<Leader>Af",
                function()
                    require("avante.api").focus()
                end,
                desc = "Avante Focus",
                silent = true,
            },
            {
                "<Leader>At",
                function()
                    require("avante").toggle()
                end,
                desc = "Avante Toggle",
                silent = true,
            },
            {
                "<Leader>Ad",
                function()
                    require("avante").toggle.debug()
                end,
                desc = "Avante Debug",
                silent = true,
            },
            {
                "<Leader>Ah",
                function()
                    require("avante").toggle.hint()
                end,
                desc = "Avante Hint",
                silent = true,
            },
            {
                "<Leader>As",
                function()
                    require("avante").toggle.suggestion()
                end,
                desc = "Avante Suggestion",
                silent = true,
            },
            {
                "<Leader>Ar",
                function()
                    require("avante.repo_map").show()
                end,
                desc = "Avante Repomap",
                silent = true,
            },
        },
        opts = {
            -- add any opts here
            provider = "copilot",
            auto_suggestions_provider = "copilot",
            windows = {
                ---@type AvantePosition
                position = "right",
                wrap = true, -- similar to vim.o.wrap
                width = 35, -- default % based on available width in vertical layout
                height = 40,
                edit = {
                    border = "rounded",
                    start_insert = true, -- Start insert mode when opening the edit window
                },
                ask = {
                    floating = false, -- Open the 'AvanteAsk' prompt in a floating window
                    border = "rounded",
                    start_insert = true, -- Start insert mode when opening the ask window
                },
                mappings = {
                    ask = "<leader>Aa",
                    edit = "<leader>Ae",
                    refresh = "<leader>Ar",
                    focus = "<leader>Af",
                    toggle = {
                        default = "<leader>At",
                        debug = "<leader>Ad",
                        hint = "<leader>Ah",
                        suggestion = "<leader>As",
                        repomap = "<leader>Ar",
                    },
                },
            },
        },
        -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
        build = "make",
        -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "stevearc/dressing.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            --- The below dependencies are optional,
            "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
            "zbirenbaum/copilot.lua", -- for providers='copilot'
            {
                -- support for image pasting
                "HakonHarnes/img-clip.nvim",
                event = "VeryLazy",
                opts = {
                    -- recommended settings
                    default = {
                        embed_image_as_base64 = false,
                        prompt_for_file_name = false,
                        drag_and_drop = {
                            insert_mode = true,
                        },
                        -- required for Windows users
                        use_absolute_path = true,
                    },
                },
            },
            {
                -- Make sure to set this up properly if you have lazy=true
                "MeanderingProgrammer/render-markdown.nvim",
                opts = {
                    file_types = {
                        -- "markdown",
                        "Avante",
                    },
                },
                ft = {
                    -- "markdown",
                    "Avante",
                },
            },
        },
    },
}