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

vim.schedule(function()
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
    vim.pack.add({
        "https://github.com/stevearc/conform.nvim",
    })

    local conform = require("conform")

    local formatters_by_ft = {
        lua = {
            stop_after_first = true,
            "stylua",
        },
        go = {
            stop_after_first = true,
            "goimports",
            "gofmt",
            lsp_format = "fallback",
        },
        proto = {
            stop_after_first = true,
            "buf",
        },
    }

    -- TODO: if the current folder DOES NOT have a prettier config file, use oxcfmt, as it's faster!
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
        "php",
        "svg",
    }) do
        formatters_by_ft[language] = {
            stop_after_first = true,
            -- I tested a second time and it is still leaving zombies processes after closing nvim 2024-09-27
            -- https://github.com/fsouza/prettierd/issues/645
            -- "prettierd",
            "prettier",
        }
    end

    conform.setup({
        notify_no_formatters = true,
        formatters_by_ft = formatters_by_ft,
        formatters = {
            prettier = {
                args = function(self, ctx)
                    -- https://prettier.io/docs/configuration.html
                    local has_cwd = vim.fs.root(ctx.buf or 0, {
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
                    })

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
                        vim.list_extend(config, { "--prose-wrap", "always" })
                    end

                    if ft == "svg" then
                        vim.list_extend(config, { "--parser", "html" })
                    end

                    return config
                end,
            },
        },
        format_on_save = function(bufnr)
            if not shouldFormat() then
                return
            end

            return {
                timeout_ms = 1000,
                lsp_format = "fallback",
            }
        end,
    })

    -- https://github.com/stevearc/conform.nvim/blob/f9ef25a7ef00267b7d13bfc00b0dea22d78702d5/doc/recipes.md#lazy-loading-with-lazynvim
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

    vim.api.nvim_create_user_command("FormatCurrentBuffer", function(args)
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
    end, { range = true })

    vim.api.nvim_create_user_command("FormatOnSaveDisable", function()
        vim.g.format_on_save = false
    end, { desc = "Disable autoformat-on-save" })

    vim.api.nvim_create_user_command("FormatOnSaveEnable", function()
        vim.g.format_on_save = true
    end, { desc = "Enable autoformat-on-save" })

    vim.keymap.set(
        { "n", "v" },
        "<leader>bf",
        "<CMD>FormatCurrentBuffer<CR>",
        { desc = "Format Current Buffer" }
    )
end)
