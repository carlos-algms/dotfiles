-- Default to true to not have to enable it for every project
if vim.g.format_on_save == nil then
    vim.g.format_on_save = true
end

vim.g.format_on_save_exclude = {
    "**/node_modules/**",
    "**/dist/**",
    "**/build/**",
    "**/vendor/**",
    "**/target/**",
    "**/bundle/**",
    "**/packer_compiled.lua",
    "**/packer_plugins/**",
    "**/autoload/**",
    "**/tmp/**",
    -- "**/temp/**", -- too generic, I have projects in temp folder
}

-- Individually disable format on save by file type
vim.g.format_on_save_disabled = {}

local prettier_config_files = {
    ".prettierrc",
    ".prettierrc.json",
    ".prettierrc.yml",
    ".prettierrc.yaml",
    ".prettierrc.json5",
    ".prettierrc.js",
    "prettier.config.js",
    ".prettierrc.ts",
    "prettier.config.ts",
    ".prettierrc.mjs",
    "prettier.config.mjs",
    ".prettierrc.mts",
    "prettier.config.mts",
    ".prettierrc.cjs",
    "prettier.config.cjs",
    ".prettierrc.cts",
    "prettier.config.cts",
    ".prettierrc.toml",
}

-- https://oxc.rs/docs/guide/usage/formatter/config
local oxfmt_config_files = {
    ".oxfmtrc.json",
    ".oxfmtrc.jsonc",
    "oxfmt.config.ts",
    "oxfmt.config.mts",
    "oxfmt.config.cts",
    "oxfmt.config.js",
    "oxfmt.config.mjs",
    "oxfmt.config.cjs",
}

--- Cache: project root path → "oxfmt" | "prettier"
---@type table<string, string>
local formatter_cache = {}

---@param bufnr integer
---@return string
local function pick_formatter(bufnr)
    local root = vim.fs.root(bufnr, { ".git", "package.json" })
        or vim.fn.getcwd()

    if formatter_cache[root] == nil then
        if vim.fs.root(bufnr, oxfmt_config_files) then
            formatter_cache[root] = "oxfmt"
        else
            formatter_cache[root] = "prettier"
        end
    end

    return formatter_cache[root]
end

local function shouldFormat()
    -- disabled globally for all file types
    if not vim.g.format_on_save then
        return false
    end

    -- check if the file type isn't disabled individually
    local disabled = vim.g.format_on_save_disabled[vim.bo.filetype] or false

    if disabled then
        print("Format on save disabled for " .. vim.bo.filetype)
        return false
    end

    -- local excluded = false
    local filePath = vim.fn.expand("%:p")

    for _, pattern in ipairs(vim.g.format_on_save_exclude) do
        local cmd =
            string.format('"%s" =~ glob2regpat("%s")', filePath, pattern)
        local result = vim.api.nvim_eval(cmd)
        if result > 0 then
            vim.notify(
                "Format on save disabled for pattern: " .. pattern,
                vim.log.levels.WARN
            )
            return false
        end
    end

    return true
end

return {
    {
        -- Installed Conform as it is used by LazyVim
        "stevearc/conform.nvim",
        -- event = { "BufWritePre" },
        -- cmd = { "ConformInfo" },
        lazy = false,
        keys = {
            {
                "<leader>bf",
                "<CMD>FormatCurrentBuffer<CR>",
                mode = { "n", "v" },
                desc = "Format Current Buffer",
            },
        },

        --- @type conform.setupOpts
        opts = {
            notify_no_formatters = true,
            formatters_by_ft = {
                lua = {
                    stop_after_first = true,
                    "stylua",
                },
                go = {
                    stop_after_first = true,
                    "goimports",
                    "gofmt",
                    -- "goimports-reviser",
                    lsp_format = "fallback",
                },
                -- python = { stop_after_first = true, "black" },
                proto = {
                    stop_after_first = true,
                    "buf",
                },
            },
            formatters = {
                -- Disabled, as it requires go.mod file to be present, and I just want to format
                -- ["goimports-reviser"] = {
                --     prepend_args = { "-rm-unused", "-set-alias" },
                -- },
                oxfmt = {
                    command = "oxfmt",
                    args = { "--stdin-filepath", "$FILENAME" },
                    stdin = true,
                },

                prettier = {
                    args = function(self, ctx)
                        local has_cwd =
                            vim.fs.root(ctx.buf or 0, prettier_config_files)

                        if has_cwd then
                            return { "--stdin-filepath", "$FILENAME" }
                        end

                        local config = {
                            "--stdin-filepath",
                            "$FILENAME",
                            "--single-quote",
                            "--trailing-comma",
                            "all",
                            "--arrow-parens",
                            "always",
                        }

                        local ft = vim.bo[ctx.buf].filetype

                        if ft == "markdown" then
                            vim.list_extend(
                                config,
                                { "--prose-wrap", "always" }
                            )
                        end

                        if ft == "svg" then
                            vim.list_extend(config, { "--parser", "html" })
                        end

                        return config
                    end,
                },
            },
            -- log_level = vim.log.levels.DEBUG,
            format_on_save = function(bufnr)
                if not shouldFormat() then
                    return
                end

                return {
                    timeout_ms = 1000,
                    lsp_format = "fallback",
                }
            end,
        },

        init = function()
            -- https://github.com/stevearc/conform.nvim/blob/f9ef25a7ef00267b7d13bfc00b0dea22d78702d5/doc/recipes.md#lazy-loading-with-lazynvim
            vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
        end,

        ---@param opts conform.setupOpts
        config = function(_, opts)
            local conform = require("conform")
            local formatters_by_ft = opts.formatters_by_ft or {}

            for _, language in ipairs({
                "typescript",
                "typescriptreact",
                "javascript",
                "javascriptreact",
                "json",
                "jsonc",
                "html",
                "css",
                "scss",
                "markdown",
                "yaml",
            }) do
                formatters_by_ft[language] = function(bufnr)
                    return { pick_formatter(bufnr), stop_after_first = true }
                end
            end

            -- oxfmt has no php or svg support, always use prettier
            for _, language in ipairs({ "php", "svg" }) do
                formatters_by_ft[language] = {
                    "prettier",
                    stop_after_first = true,
                }
            end

            conform.setup(opts)

            vim.api.nvim_create_user_command(
                "FormatCurrentBuffer",
                function(args)
                    local range = nil
                    if args.count ~= -1 then
                        local end_line = vim.api.nvim_buf_get_lines(
                            0,
                            args.line2 - 1,
                            args.line2,
                            true
                        )[1]
                        range = {
                            start = { args.line1, 0 },
                            ["end"] = { args.line2, end_line:len() },
                        }
                    end

                    conform.format({
                        async = true,
                        lsp_format = "fallback",
                        range = range,
                    })
                end,
                { range = true }
            )

            vim.api.nvim_create_user_command(
                "FormatOnSaveDisable",
                function(args)
                    vim.g.format_on_save = false
                end,
                {
                    desc = "Disable autoformat-on-save",
                }
            )

            vim.api.nvim_create_user_command("FormatOnSaveEnable", function()
                vim.g.format_on_save = true
            end, {
                desc = "Enable autoformat-on-save",
            })
        end,
    },
}
