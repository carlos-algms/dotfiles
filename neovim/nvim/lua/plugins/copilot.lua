return {
    {
        "CopilotC-Nvim/CopilotChat.nvim",

        branch = "main",

        enabled = vim.g.has_node,

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
        --- @type CopilotChat.config
        opts = {
            -- https://github.com/CopilotC-Nvim/CopilotChat.nvim?tab=readme-ov-file#configuration
            -- debug = true, -- Enable debugging

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
                        accept_line = false,
                        next = "<A-k>",
                        prev = "<A-j>",
                        dismiss = "<A-h>",
                    },
                },
                panel = { enabled = true },
                filetypes = {
                    yaml = true,
                    markdown = true,
                    gitcommit = true,
                    gitrebase = true,
                },
            })
        end,
    },

    -- It's too slow and with fewer suggestions
    -- {
    --     "zbirenbaum/copilot-cmp",
    --     enabled = false,
    --     dependencies = {},
    --     config = function()
    --         require("copilot_cmp").setup()
    --     end,
    -- },

    -- Disabled to test the lua version
    -- {
    --     "github/copilot.vim",
    --     event = { "VeryLazy" },
    --     enabled = false,
    --     keys = {
    --         {
    --             "<C-l>",
    --             [[ copilot#Accept("\\<CR>") ]],
    --             mode = "i",
    --             desc = "Copilot accept suggestion",
    --             expr = true,
    --             replace_keycodes = false,
    --         },
    --         {
    --             "<C-.>",
    --             "<Plug>(copilot-accept-word)",
    --             mode = "i",
    --             desc = "Copilot accept word",
    --         },
    --         {
    --             "<C-;>",
    --             "<Plug>(copilot-next)",
    --             mode = "i",
    --             desc = "Copilot next suggestion",
    --         },
    --         {
    --             "<C-,>",
    --             "<Plug>(copilot-suggest)",
    --             mode = "i",
    --             desc = "Copilot suggest",
    --         },
    --     },
    --     -- used init instead of config because copilot was holding Tab anyway
    --     init = function()
    --         -- I will use CMP mappings to have <Tab> fallback
    --         vim.g.copilot_no_tab_map = true
    --         vim.g.copilot_assume_mapped = true
    --         vim.g.copilot_tab_fallback = ""

    --         vim.g.copilot_filetypes = {
    --             yml = true,
    --             yaml = true,
    --             markdown = true,
    --             gitcommit = true,
    --             sagarename = false,
    --             spectre_panel = false,
    --             DressingInput = false,
    --             oil = false,
    --         }
    --     end,
    -- },
}
