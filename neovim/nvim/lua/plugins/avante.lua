local M = {
    {
        "yetone/avante.nvim",

        -- enabled = not vim.g.is_ssh,

        -- it seems better to lazy load on event, as the generate template error doesn't happen
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

        --- @module "avante"
        --- @type avante.Config
        opts = {
            -- https://www.reddit.com/r/neovim/comments/1lqc6ar/a_touch_up_on_avantenvim_that_make_it_awesome/
            -- https://github.com/yetone/avante.nvim/blob/main/lua/avante/templates/agentic.avanterules
            override_prompt_dir = vim.fn.stdpath("config") .. "/avante_prompts",

            ---@alias AvanteProviders "copilot" | "ollama" | "claude" | "claude-code" | "gemini" | "gemini-cli" | "openai"

            ---@type AvanteProviders
            provider = vim.g.is_ssh and "copilot" or "claude-code",

            ---@type AvanteProviders
            auto_suggestions_provider = "copilot",

            -- https://github.com/yetone/avante.nvim?tab=readme-ov-file#acp-configuration
            acp_providers = {
                ["gemini-cli"] = {
                    command = "gemini",
                    args = { "--experimental-acp" },
                    env = {
                        NODE_NO_WARNINGS = "1",
                        GEMINI_API_KEY = os.getenv("GEMINI_API_KEY"),
                    },
                },
                ["claude-code"] = {
                    command = "pnpm",
                    args = {
                        "dlx",
                        "@zed-industries/claude-code-acp",
                    },
                    env = {
                        NODE_NO_WARNINGS = "1",
                        ANTHROPIC_API_KEY = os.getenv(
                            "AVANTE_ANTHROPIC_API_KEY"
                        ),
                    },
                },
            },

            providers = {
                ---@type AvanteSupportedProvider
                copilot = {
                    -- model = "claude-3.7-sonnet",
                    model = "gpt-4.1-2025-04-14",
                },

                ---@type AvanteSupportedProvider
                claude = {
                    endpoint = "https://api.anthropic.com",
                    --- @type "claude-sonnet-4-5-20250929" | "claude-opus-4-1-20250805" | "claude-sonnet-4-20250514"
                    model = "claude-opus-4-1-20250805",
                    api_key_name = "cmd:echo $SHARED_ANTHROPIC_API_KEY",
                    timeout = 30000,
                    extra_request_body = {
                        temperature = 0.75,
                        -- max_tokens = 32000,
                    },
                },

                --- @type AvanteSupportedProvider
                -- lm_studio = {
                --     __inherited_from = "openai",
                --     ["local"] = true,
                --     api_key_name = "",
                --     endpoint = "http://localhost:1234/v1",
                --
                --     -- model = "qwen/qwen3-coder-30b",
                --     -- context_window = 256000,
                --
                --     model = "openai/gpt-oss-20b", -- it was returning empty responses
                --     context_window = 131072,
                --
                --     is_env_set = function()
                --         return true
                --     end,
                -- },

                --- @type AvanteSupportedProvider
                -- ollama = {
                --     ["local"] = true,
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

            ---@type AvanteSlashCommand[]
            slash_commands = {},

            ---@type AvanteShortcut[]
            shortcuts = {
                {
                    name = "explain",
                    description = "Explain without making any changes",
                    details = "Explain the file or the selected code",
                    prompt = "Explain the selected code, or the entire file without making any changes.",
                },
                {
                    name = "q",
                    description = "Answer a Question",
                    details = "Answer the question without making any changes",
                    prompt = "Answer the question without making any changes. Consider the context, selected code or the entire file.",
                },
                {
                    name = "plan",
                    description = "/plan implement the fibonacci function in this file",
                    details = "Create a detailed plan with actionable steps to achieve the goal.\n/plan create a sum function that adds two numbers",
                    prompt = ([[
                            You won't make any changes, just create a detailed plan with actionable steps.
                            Be concise, clear, and structured.
                            Avoid filler words and generic content like: should do, could do, etc.
                            I want it to be very specific, actionable, and direct like: install X, run Y, create Z, remove A, refactor B to do C, etc.
                            Make it a numbered todo-list, so it's possible to stop and continue from any step, or refine and increase the number of steps.
                            Don't include a "next steps" section.
                            Use markdown format with headings, subheadings, and bullet points, use emojis when appropriate.
                            Use nested lists where the first level is the file name and the second level is all the actions to be done in that file.
                            State relative location like "at the top", "at the bottom", "in the middle", "after the imports", inside of the function F, etc.
                            Write the plan to a markdown file, derive the file name from the goal.
                        ]]):gsub("^%s+", ""):gsub(
                        "\n%s+",
                        "\n"
                    ),
                },
            },

            behaviour = {
                auto_set_keymaps = false,
                auto_suggestions = false,
                auto_apply_diff_after_generation = true, -- doesn't seem to work with ACP
                auto_approve_tool_permissions = false,
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

        keys = {
            {
                "<A-i>o",
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
                "<A-i>s",
                function()
                    require("avante.api").stop()
                end,
                desc = "Avante Stop",
                silent = true,
                mode = { "n", "v", "i" },
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

                completions = {
                    lsp = { enabled = true },
                },
            },
        },
    },
}

return M
