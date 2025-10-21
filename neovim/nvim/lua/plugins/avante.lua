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

        opts = function(_, _maybeOpts)
            ---@alias AvanteProviders "copilot" | "ollama" | "claude" | "claude-code" | "gemini" | "gemini-cli" | "openai" | "codex-acp"
            ---@type AvanteProviders
            local provider = "claude-code"

            local claudeKeyName = "CARLOS_ANTHROPIC_API_KEY"

            if vim.g.is_ssh then
                provider = "copilot"
            end

        --- @module "avante"
        --- @type avante.Config
            local config = {
            -- https://www.reddit.com/r/neovim/comments/1lqc6ar/a_touch_up_on_avantenvim_that_make_it_awesome/
            -- https://github.com/yetone/avante.nvim/blob/main/lua/avante/templates/agentic.avanterules
                override_prompt_dir = vim.fn.stdpath("config")
                    .. "/avante_prompts",

                provider = provider,

            ---@type AvanteProviders
            auto_suggestions_provider = "copilot",

            -- https://github.com/yetone/avante.nvim?tab=readme-ov-file#acp-configuration
            acp_providers = {
                ["gemini-cli"] = {
                    command = "gemini",
                    args = { "--experimental-acp" },
                    env = {
                        NODE_NO_WARNINGS = "1",
                            DISABLE_ZOXIDE = "1",
                            -- GEMINI_API_KEY = os.getenv("GEMINI_API_KEY"),
                    },
                },
                ["claude-code"] = {
                        command = "claude-code-acp", -- I installed it globally with `pnpm i -g @zed-industries/claude-code-acp`, to avoid issues with projects using only npm
                        -- command = "pnpm",
                        -- args = {
                        --     "dlx",
                        --     "@zed-industries/claude-code-acp",
                        -- },
                    env = {
                        NODE_NO_WARNINGS = "1",
                            DISABLE_ZOXIDE = "1",
                            ANTHROPIC_API_KEY = os.getenv(claudeKeyName),
                        },
                    },
                    ["codex-acp"] = {
                        -- https://github.com/zed-industries/codex-acp/releases
                        -- xattr -dr com.apple.quarantine ~/.local/bin/codex-acp
                        command = "codex-acp",
                        args = {},
                        env = {
                            DISABLE_ZOXIDE = "1",
                    },
                },
            },

            providers = {
                ---@type AvanteSupportedProvider
                copilot = {
                    -- model = "claude-3.7-sonnet",
                    model = "gpt-4.1",
                },

                ---@type AvanteSupportedProvider
                claude = {
                    --- @type "claude-sonnet-4-5-20250929" | "claude-opus-4-1-20250805" | "claude-sonnet-4-20250514"
                    model = "claude-sonnet-4-5-20250929",
                    -- api_key_name = "cmd:echo $SHARED_ANTHROPIC_API_KEY",
                        -- api_key_name = "cmd:echo $CARLOS_ANTHROPIC_API_KEY",
                        api_key_name = string.format(
                            "cmd:echo $%s",
                            claudeKeyName
                        ),
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
                    prompt = "Explain the selected code, or the entire file without making any changes.\n",
                },
                {
                    name = "q",
                    description = "Answer a Question",
                    details = "Answer the question without making any changes",
                    prompt = "Answer the question without making any changes. Consider the context, selected code or the entire file.\n\n",
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
                            Write the plan to a markdown file, derive the file name from the goal prefixed with `plan-`,
                            the file should be saved next to the selected file, or in the current working directory.
                            After you create, or edit this file, run prettier to format it like: `prettier --prose-wrap always --print-width 80 --write "FILENAME.md"`
                    ]]):gsub("^%s+", ""):gsub(
                            "\n%s+",
                            "\n"
                        ),
                },
                {
                    name = "conventional_commit",
                    description = "Create a conventional commit message and commit",
                    details = "Create a conventional commit message based on the changes made in the project, stage, commit",
                    prompt = ([[
                        You're going to commit the changes on the user's behalf using the conventional commit strategy.
                        If there're no changed files, abort and tell the user the reason.
                        If the user is on the `main` or `master` branch, you must create a new branch with the pattern `cgomes/<scope>-short-description` before committing.
                    ]]):gsub("^%s+", ""):gsub(
                            "\n%s+",
                            "\n"
                        ),
                },

                {
                    name = "conventional_message",
                    description = "Create a conventional message but don't commit",
                    details = "Create a conventional commit message based on the changes made in the project",
                    prompt = ([[
                        You're only going to generate the conventional commit message, don't commit.
                        If you're on the file `.git/COMMIT_EDITMSG`, I use the verbose commit command, so all the information you need to create a good commit message is there.
                        Avoid reading other files.
                        Follow the standard conventional commit message generation protocol.
                        If you are in the file `.git/COMMIT_EDITMSG`,
                        apply the message to the top of the file, otherwise just send me the generated text as a normal message.
                        This is usually a long file, so you can ignore cspell spell diagnostics and other linter warnings.
                    ]]):gsub("^%s+", ""):gsub(
                            "\n%s+",
                            "\n"
                        ),
                },
            },

            behaviour = {
                auto_set_keymaps = false,
                auto_suggestions = false,
                auto_apply_diff_after_generation = false,
                support_paste_from_clipboard = false,
                minimize_diff = true,
                    enable_token_counting = false,
                auto_approve_tool_permissions = false,
                    confirmation_ui_style = "inline_buttons",
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
            }

            return config
        end,

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
                "<A-i>c",
                function()
                    -- I `edit()` with a prefilled text is crashing, leaving it as an example
                    -- local current_file = vim.fn.expand("%:p")
                    -- if current_file:match("%.git/COMMIT_EDITMSG$") then
                    --     local _, selection = require("avante").get()
                    --     if not selection then
                    --         vim.cmd("normal! ggV")
                    --     end
                    --     require("avante.api").edit(
                    --         "#conventional_message",
                    --         1,
                    --         1
                    --     )
                    -- else
                    -- end
                    require("avante.api").ask({
                        ask = true,
                        new_chat = true,
                        question = "#conventional_message",
                    })
                end,
                desc = "Avante write conventional commit message",
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
                "<A-i>s",
                function()
                    require("avante.api").stop()
                end,
                desc = "Avante Stop",
                silent = true,
                mode = { "n", "v", "i" },
            },

            {
                "<A-i>a",
                function()
                    require("avante.api").add_selected_file(
                        vim.fn.expand("%:.")
                    )
                end,
                desc = "Add current file to context",
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
