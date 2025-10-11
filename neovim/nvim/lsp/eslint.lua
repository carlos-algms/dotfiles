local forbidden_folders = { "node_modules", "dist", "build", "vendor" }

---@type vim.lsp.Config
return {
    workspace_required = true,

    root_markers = {
        ".eslintrc.js",
        ".eslintrc.json",
        ".eslintrc.mjs",
        ".eslintrc.yaml",
        ".eslintrc.yml",
        ".eslintrc",
        "eslint.config.js",
        "eslint.config.mjs",
        "eslint.config.ts",
        "node_modules/",
        "package.json",
    },

    root_dir = function(bufnr, on_dir)
        -- I had to validate the buffer name because eslint-ls
        -- was crashing when running inside node_modules

        local bufname = vim.api.nvim_buf_get_name(bufnr) or ""

        for _, folder in ipairs(forbidden_folders) do
            if bufname:find(folder, 1, true) then
                return
            end
        end

        local cwd = vim.uv.cwd()
        on_dir(cwd)
    end,

    settings = {
        options = {
            -- Disabled, as if a config file is found, it won't start. and this is different depending o eslint version
            -- overrideConfig = {
            --     ignores = {
            --         "**.vscode**",
            --         "**/nvm/**",
            --         "**/node_modules/**",
            --         "**/lib/**",
            --         "**/dist/**",
            --         "**/public/**",
            --         "**/build/**",
            --     },
            -- },
        },
    },
}
