return {
    {
        "CopilotC-Nvim/CopilotChat.nvim",

        branch = "main",

        enabled = false, -- vim.g.has_node,

        build = "make tiktoken", -- Only on MacOS or Linux

        dependencies = {
            { "zbirenbaum/copilot.lua" },
            -- { "github/copilot.vim" },
            { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
        },

        cmd = {
            "CopilotChat",
            "CopilotChatOpen",
            "CopilotChatClose",
            "CopilotChatToggle",
        },

        keys = {
            {
                "<Leader>C",
                "<CMD>CopilotChatOpen<CR>",
                desc = "Open Copilot Chat",
                mode = { "n", "v" },
            },
        },

        --- @module "CopilotChat"
        --- @type CopilotChat.config.Config
        opts = {
            -- https://github.com/CopilotC-Nvim/CopilotChat.nvim?tab=readme-ov-file#configuration
            -- debug = true, -- Enable debugging

            -- model = "gpt-4o",
            model = "gpt-4.1", -- use CopilotChatModels to see all models
            -- model = "claude-3.7-sonnet", -- 'gpt-4o', -- Default model to use, see ':CopilotChatModels'
            -- model = "claude-3.7-sonnet-thought",

            sticky = {
                "#buffer",
            },

            insert_at_end = true,

            mappings = {
                ---@diagnostic disable-next-line: missing-fields
                reset = {
                    normal = "<localleader>r",
                    insert = "<localleader><C-r>",
                },
            },
        },
        -- See Commands section for default commands if you want to lazy load on them
    },

    {
        "zbirenbaum/copilot.lua",

        cmd = "Copilot",

        event = "VeryLazy",

        enabled = vim.g.has_node,

        dependencies = {
            {
                "copilotlsp-nvim/copilot-lsp",
                init = function()
                    vim.g.copilot_nes_debounce = 500
                end,
            },
        },

        config = function()
            require("copilot").setup({
                -- it seems there's only 1 model available for autocompletion
                -- https://github.com/github/copilot.vim/issues/77#issuecomment-2848712690
                -- so I'll keep it commented out for now
                -- copilot_model = "copilot:claude-3.7-sonnet",
                suggestion = {
                    enabled = true,
                    auto_trigger = true,
                    hide_during_completion = false,
                    keymap = {
                        accept = "<C-l>",
                        accept_word = "<C-.>",
                        accept_line = "<C-j>",
                        next = "<A-]>",
                        prev = "<A-[>",
                        dismiss = "<A-h>",
                    },
                },

                panel = { enabled = true },

                nes = {
                    enabled = false,
                    auto_trigger = false,
                    keymap = {
                        accept_and_goto = "<C-y>",
                        accept = false,
                        dismiss = "<Esc>",
                    },
                },

                filetypes = {
                    yaml = true,
                    markdown = true,
                    gitcommit = true,
                    gitrebase = true,
                },

                -- it either stopped working in node v22, or it was hiding the error messages before
                copilot_node_command = {
                    "node",
                    "--experimental-sqlite",
                },
            })
        end,
    },
}
