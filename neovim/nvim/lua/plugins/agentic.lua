local set = vim.keymap.set
local loaded = false

local function load_agentic()
    if loaded then
        return
    end
    loaded = true

    local spec = {
        src = "https://github.com/carlos-algms/agentic.nvim",
    }

    if not vim.g.is_ssh then
        local local_path = vim.uv.os_homedir() .. "/projects/agentic.nvim"

        if vim.uv.fs_stat(local_path) then
            spec = {
                src = local_path,
                name = "agentic.nvim",
            }
        end
    end

    vim.pack.add({ spec })

    --- @module 'agentic'
    --- @type agentic.PartialUserConfig
    local config = {
        debug = false,
        provider = "claude-agent-acp",
        ---@diagnostic disable-next-line: missing-fields
        windows = {
            position = "right",
            width = "40%",
            height = "25%",
        },
        acp_providers = {
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
        },
    }

    if vim.g.is_ssh and os.getenv("CARLOS_ANTHROPIC_API_KEY") ~= nil then
        local key =
            { ANTHROPIC_API_KEY = os.getenv("CARLOS_ANTHROPIC_API_KEY") }
        config.acp_providers["claude-acp"] = { env = key }
        config.acp_providers["claude-agent-acp"] = { env = key }
    end

    require("agentic").setup(config)
end

local nvi = { "n", "v", "i" }

set(nvi, "<C-\\>", function()
    load_agentic()
    require("agentic").toggle({ auto_add_to_context = false })
end, { desc = "Agentic Open" })

set({ "n", "v" }, "<C-'>", function()
    load_agentic()
    require("agentic").add_selection_or_file_to_context()
end, { desc = "Agentic Add Selection to context" })

set(nvi, "<C-,>", function()
    load_agentic()
    require("agentic").new_session({ auto_add_to_context = false })
end, { desc = "Agentic New Session" })

set(nvi, "<C-S-,>", function()
    load_agentic()
    require("agentic").new_session()
end, { desc = "Agentic New Session" })

set(nvi, "<C-A-n>", function()
    load_agentic()
    require("agentic").new_session_with_provider()
end, { desc = "Agentic New Session with provider selection" })

set(nvi, "<C-t>", function()
    load_agentic()
    require("agentic").stop_generation()
end, { desc = "Agentic Stop current generation" })

set(nvi, "<A-i>r", function()
    load_agentic()
    require("agentic").restore_session()
end, { desc = "Agentic Restore session" })

set(nvi, "<A-i>l", function()
    load_agentic()
    require("agentic").rotate_layout({ "right", "bottom" })
end, { desc = "Agentic rotate layout" })
