local M = {
    {
        dir = vim.uv.os_homedir() .. "/projects/agentic.nvim",
        dev = true,
        name = "agentic.nvim",

        "carlos-algms/agentic.nvim",

        event = "VeryLazy",

        version = false,

        opts = function(_, _maybeOpts)
            local claudeKeyName = "CARLOS_ANTHROPIC_API_KEY"

            ---@module 'agentic'
            ---@type agentic.UserConfig
            local config = {
                debug = true,

                --- @type agentic.UserConfig.ProviderName
                provider = "claude-acp",

                acp_providers = {
                    ["claude-acp"] = {
                        command = "claude-code-acp",
                        env = {
                            NODE_NO_WARNINGS = "1",
                            IS_AI_TERMINAL = "1",
                            ANTHROPIC_API_KEY = os.getenv(claudeKeyName),
                        },
                    },
                },
            }

            return config
        end,

        keys = {
            {
                "<C-\\>",
                function()
                    require("agentic").toggle()
                end,
                desc = "Agentic Open",
                silent = true,
                mode = { "n", "v", "i" },
            },

            {
                "<C-'>",
                function()
                    require("agentic").add_selection_or_file_to_context()
                end,
                desc = "Agentic Add Selection to context",
                silent = true,
                mode = { "n", "v" },
            },

            {
                "<C-,>",
                function()
                    require("agentic").new_session()
                end,
                desc = "Agentic New Session",
                silent = true,
                mode = { "n", "v", "i" },
            },
        },

        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "folke/snacks.nvim",
            "nvim-tree/nvim-web-devicons",
        },
    },
}

return M
