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

local function shouldFormat()
    -- disabled globally for all file types
    if not vim.g.format_on_save then
        return false
    end

    -- check if the file type isn't disabled individually
    local disabled = vim.g.format_on_save_disabled[vim.bo.filetype] or false

    if disabled then
        vim.notify("Format on save disabled for " .. vim.bo.filetype, "warn")
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
                "warn"
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
                lua = { stop_after_first = true, "stylua" },
                go = {
                    stop_after_first = true,
                    -- "goimports-reviser",
                    lsp_format = "fallback",
                },
                -- python = { stop_after_first = true, "black" },
            },
            formatters = {
                -- Disabled, as it requires go.mod file to be present, and I just want to format
                -- ["goimports-reviser"] = {
                --     prepend_args = { "-rm-unused", "-set-alias" },
                -- },
            },
            -- log_level = vim.log.levels.DEBUG,
            format_on_save = function(bufnr)
                if not shouldFormat() then
                    return
                end

                return {
                    timeout_ms = 500,
                    lsp_format = "fallback",
                }
            end,
        },

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
