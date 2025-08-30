local M = {
    {
        "yetone/avante.nvim",

        -- enabled = not vim.g.is_ssh,

        -- it seems better to lazy load  on event, as the generate template error doesn't happen
        event = "VeryLazy",
        -- lazy = false,

        cmd = {
            "AvanteAsk",
            "AvanteChat",
            "AvanteEdit",
            "AvanteStop",
            "AvanteChatNew",
            "AvanteModels",
        },

        version = false, -- set this if you want to always pull the latest change

        build = "make", -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
        -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows

        keys = {
            {
                "<A-i>",
                function()
                    require("avante.api").ask({
                        ask = true,
                    })
                end,
                desc = "Avante Ask",
                silent = true,
                mode = { "n", "v", "i" },
            },

            {
                "<A-i>n",
                function()
                    require("avante.api").ask({
                        ask = true,
                        new_chat = true,
                    })
                end,
                desc = "Avante new Chat",
                silent = true,
                mode = { "n", "v", "i" },
            },

            {
                "<A-i>e",
                function()
                    require("avante.api").edit()
                end,
                desc = "Avante Edit",
                silent = true,
                mode = { "n", "v" },
            },

            {
                "<A-i>r",
                function()
                    require("avante.api").refresh()
                end,
                desc = "Avante Refresh",
                silent = true,
                mode = { "n", "v" },
            },

            {
                "<A-i>f",
                function()
                    require("avante.api").focus()
                end,
                desc = "Avante Focus",
                silent = true,
                mode = { "n", "v", "i" },
            },

            {
                "<A-i>t",
                function()
                    require("avante").toggle()
                end,
                desc = "Avante Toggle",
                silent = true,
                mode = { "n", "v", "i" },
            },

            {
                "<Leader>Ar",
                function()
                    require("avante.repo_map").show()
                end,
                desc = "Avante RepoMap",
                silent = true,
                mode = { "n", "v" },
            },

            {
                "<A-i>S",
                function()
                    require("avante.api").stop()
                end,
                desc = "Avante Stop",
                silent = true,
                mode = { "n", "v", "i" },
            },
        },

        --- @module "avante"
        --- @type avante.Config
        opts = {
            -- https://www.reddit.com/r/neovim/comments/1lqc6ar/a_touch_up_on_avantenvim_that_make_it_awesome/
            -- https://github.com/yetone/avante.nvim/blob/main/lua/avante/templates/agentic.avanterules
            override_prompt_dir = vim.fn.stdpath("config") .. "/avante_prompts",

            ---@type "copilot" | "ollama" | "claude" | "openai" | "azure" | "gemini"
            provider = "copilot",

            providers = {
                ---@type AvanteSupportedProvider
                copilot = {
                    -- model = "claude-3.7-sonnet",
                    model = "claude-3.7-sonnet-thought",
                    -- model = "gpt-4.1-2025-04-14",
                },

                ---@type AvanteSupportedProvider
                -- ollama = {
                --     endpoint = "http://127.0.0.1:11434",
                --     -- model = "qwen3:4b-thinking-2507-q4_K_M",
                --     model = "gpt-oss:20b",
                --     -- model = "codegemma:7b-instruct-v1.1-q5_K_M",
                --     is_env_set = function()
                --         return true
                --     end,
                --     context_window = 128000,
                -- },
            },

            auto_suggestions_provider = "copilot",

            behaviour = {
                auto_set_keymaps = false,
                auto_suggestions = false,
            },

            selection = {
                hint_display = "none",
            },

            windows = {
                position = "right",
                wrap = true, -- similar to vim.o.wrap
                width = 40, -- default % based on available width in vertical layout
                input = {
                    height = 12,
                },
                edit = {
                    border = "rounded",
                    start_insert = true, -- Start insert mode when opening the edit window
                },
                ask = {
                    floating = false, -- Open the 'AvanteAsk' prompt in a floating window
                    border = "rounded",
                    start_insert = true, -- Start insert mode when opening the ask window
                },
            },
        },

        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "folke/snacks.nvim", -- for input provider snacks
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
                        "AvanteTodos",
                        "copilot-chat",
                    },
                },
                ft = {
                    -- "markdown",
                    "Avante",
                    "AvanteTodos",
                    "copilot-chat",
                },
            },
        },
    },
}

return M
