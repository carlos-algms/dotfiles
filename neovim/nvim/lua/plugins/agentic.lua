local M = {
    "carlos-algms/agentic.nvim",

    version = false,

    dependencies = {
        {
            "HakonHarnes/img-clip.nvim",
            opts = {},
        },
    },

    opts = function(_, _maybeOpts)
        ---@module 'agentic'
        ---@type agentic.UserConfig
        local config = {
            debug = false,

            --- @type agentic.UserConfig.ProviderName
            provider = "claude-acp",

            windows = {
                width = "40%",
            },
        }

            config.acp_providers = {
            ["opencode-acp"] = {
                    env = {
                    CARLOS_ANTHROPIC_API_KEY = os.getenv(
                            "CARLOS_ANTHROPIC_API_KEY"
                        ),
                    },
                },
            }

        if vim.g.is_ssh and os.getenv("CARLOS_ANTHROPIC_API_KEY") ~= nil then
            config.acp_providers["claude-acp"] = {
                env = {
                    ANTHROPIC_API_KEY = os.getenv("CARLOS_ANTHROPIC_API_KEY"),
                },
            }
        end

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

        {
            "<C-t>",
            function()
                require("agentic").stop_generation()
            end,
            desc = "Agentic Stop current generation",
            silent = true,
            mode = { "n", "v", "i" },
        },
    },
}

if not vim.g.is_ssh then
    M.dir = vim.uv.os_homedir() .. "/projects/agentic.nvim"
    M.dev = true
    M.name = "agentic.nvim"
end

return M
