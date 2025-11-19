---@type vim.lsp.Config
return {
    root_dir = function(bufnr, on_dir)
        local bufname = vim.api.nvim_buf_get_name(bufnr) or ""

        if bufname:find("diffview") then
            return
        end

        local cwd = vim.uv.cwd()
        on_dir(cwd)
    end,
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
                    vim.api.nvim_get_runtime_file("", true),
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
