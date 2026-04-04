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
        ---@type agentic.PartialUserConfig
        local config = {
            debug = true,

            provider = "claude-agent-acp",

            ---@diagnostic disable-next-line: missing-fields
            windows = {
                position = "right",
                width = "40%",
                height = "25%",
            },
        }

        config.acp_providers = {
            ["opencode-acp"] = {
                env = {
                    CARLOS_ANTHROPIC_API_KEY = os.getenv(
                        "CARLOS_ANTHROPIC_API_KEY"
                    ),
                    COREPACK_NPM_REGISTRY = os.getenv("COREPACK_NPM_REGISTRY"),
                    COREPACK_NPM_TOKEN = os.getenv("COREPACK_NPM_TOKEN"),
                    COREPACK_INTEGRITY_KEYS = os.getenv(
                        "COREPACK_INTEGRITY_KEYS"
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
            config.acp_providers["claude-agent-acp"] = {
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
                require("agentic").toggle({ auto_add_to_context = false })
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
                require("agentic").new_session({ auto_add_to_context = false })
            end,
            desc = "Agentic New Session",
            silent = true,
            mode = { "n", "v", "i" },
        },

        {
            "<C-S-,>",
            function()
                require("agentic").new_session()
            end,
            desc = "Agentic New Session",
            silent = true,
            mode = { "n", "v", "i" },
        },

        {
            "<C-A-n>",
            function()
                require("agentic").new_session_with_provider()
            end,
            desc = "Agentic New Session with provider selection",
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

        {
            "<A-i>r",
            function()
                require("agentic").restore_session()
            end,
            desc = "Agentic Restore session",
            silent = true,
            mode = { "n", "v", "i" },
        },
        {
            "<A-i>l",
            function()
                require("agentic").rotate_layout({ "right", "bottom" })
            end,
            desc = "Agentic rotate layout",
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
