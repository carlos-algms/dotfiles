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
    "**/temp/**",
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
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>bf",
                ":FormatCurrentBuffer<CR>",
                mode = { "n", "v" },
                desc = "Format Current Buffer",
            },
        },
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "black" },
            },
        },
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
            }) do
                formatters_by_ft[language] = { { "prettierd", "prettier" } }
            end

            conform.setup(opts)

            vim.api.nvim_create_autocmd("BufWritePre", {
                pattern = "*",
                callback = function(args)
                    if not shouldFormat() then
                        return
                    end
                    conform.format({ bufnr = args.buf })
                end,
            })

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
                        lsp_fallback = true,
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
    {
        enabled = false,
        "mhartington/formatter.nvim",
        event = "VeryLazy", -- Packer doesn't seem to have this event
        -- opts = function()
        --     return require "custom.configs.formatter"
        -- end
        init = function() end,
        config = function()
            -- enable auto-formatting on save
            vim.api.nvim_create_autocmd({ "BufWritePost" }, {
                -- command = "FormatWriteLock",
                callback = function()
                    if not shouldFormat() then
                        return
                    end
                    vim.cmd("FormatWriteLock")
                end,
            })

            local util = require("formatter.util")
            require("formatter").setup({
                -- All formatter configurations are opt-in
                -- TODO: how to disable this for certain files per project??
                filetype = {
                    javascript = {
                        require("formatter.filetypes.javascript").prettier,
                    },
                    javascriptreact = {
                        require("formatter.filetypes.javascriptreact").prettier,
                    },
                    typescript = {
                        require("formatter.filetypes.typescript").prettier,
                    },
                    typescriptreact = {
                        require("formatter.filetypes.typescriptreact").prettier,
                    },
                    json = {
                        require("formatter.filetypes.json").prettier,
                    },
                    jsonc = {
                        require("formatter.filetypes.json").prettier,
                    },
                    html = {
                        require("formatter.filetypes.html").prettier,
                    },
                    css = {
                        require("formatter.filetypes.css").prettier,
                    },
                    scss = {
                        require("formatter.filetypes.css").prettier,
                    },
                    markdown = {
                        require("formatter.filetypes.markdown").prettier,
                    },
                    lua = {
                        require("formatter.filetypes.lua").stylua,
                    },
                    yaml = {
                        require("formatter.filetypes.yaml").prettier,
                    },
                    python = {
                        require("formatter.filetypes.python").black,
                    },
                    sh = {
                        require("formatter.filetypes.sh").shfmt,
                    },
                    php = {
                        function(parser)
                            local opts = {
                                exe = "prettier",
                                args = {
                                    "--stdin-filepath",
                                    util.escape_path(
                                        util.get_current_buffer_file_path()
                                    ),
                                },
                                stdin = true,
                                try_node_modules = true,
                            }

                            if parser then
                                opts["--parser"] = parser
                            end

                            return opts
                        end,
                    },
                    -- Disable it to rely on .editorconfig
                    -- ["*"] = {
                    --     require("formatter.filetypes.any").remove_trailing_whitespace,
                    -- },
                },
            })
        end,
    },
}
