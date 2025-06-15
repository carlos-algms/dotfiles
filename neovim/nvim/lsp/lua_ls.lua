---@type vim.lsp.Config
return {
    settings = {
        Lua = {
            telemetry = { enable = false },
            runtime = {
                version = "LuaJIT",
            },
            diagnostics = {
                globals = { "vim", "get_args" },
            },
            workspace = {
                library = {
                    vim.env.VIMRUNTIME,
                },
                checkThirdParty = false,
            },
            codeLens = {
                enable = true,
            },
            doc = {
                privateName = { "^_" },
            },
            hint = {
                enable = true,
                setType = false,
                paramType = true,
                paramName = "Disable",
                semicolon = "Disable",
                arrayIndex = "Disable",
            },
        },
    },
}
