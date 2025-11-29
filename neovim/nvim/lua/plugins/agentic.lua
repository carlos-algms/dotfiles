local M = {

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
        -- "nvim-tree/nvim-web-devicons",
    },
}

if not vim.g.is_ssh then
    M.dir = vim.uv.os_homedir() .. "/projects/agentic.nvim"
    M.dev = true
    M.name = "agentic.nvim"
end

return M
