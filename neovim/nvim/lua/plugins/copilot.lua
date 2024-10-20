return {
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        branch = "canary",
        lazy = true,
        dependencies = {
            { "zbirenbaum/copilot.lua" },
            -- { "github/copilot.vim" },
            { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
        },
        keys = {
            {
                "<leader>C",
                "<cmd>CopilotChatOpen<CR>",
                desc = "Open Copilot Chat",
                mode = { "n", "v" },
            },
        },
        opts = {
            -- debug = true, -- Enable debugging
            -- See Configuration section for rest
        },
        -- See Commands section for default commands if you want to lazy load on them
    },

    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "VeryLazy",
        config = function()
            require("copilot").setup({
                suggestion = {
                    enabled = true,
                    auto_trigger = true,
                    keymap = {
                        accept = "<C-l>",
                        accept_word = false,
                        accept_line = "<C-.>",
                        next = "˚", -- <Alt-k>
                        prev = "∆", -- <Alt-j>
                        dismiss = "˙", -- <Alt-h>
                    },
                },
                panel = { enabled = true },
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
