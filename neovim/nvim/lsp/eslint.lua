---@type vim.lsp.Config
return {
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
