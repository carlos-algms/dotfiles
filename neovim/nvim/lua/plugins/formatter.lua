return {
    "mhartington/formatter.nvim",
    event = "VeryLazy", -- Packer doesn't seem to have this event
    -- opts = function()
    --     return require "custom.configs.formatter"
    -- end
    init = function()
        -- Default to false to be safe on newly opened projects
        if vim.g.format_on_save == nil then
            vim.g.format_on_save = false
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
    end,
    config = function()
        -- enable auto-formatting on save
        vim.api.nvim_create_autocmd({ "BufWritePost" }, {
            -- command = "FormatWriteLock",
            callback = function()
                -- disabled globally for all file types
                if not vim.g.format_on_save then
                    return
                end

                -- check if the file type isn't disabled individually
                local disabled = vim.g.format_on_save_disabled[vim.bo.filetype]
                    or false

                if disabled then
                    vim.notify(
                        "Format on save disabled for " .. vim.bo.filetype,
                        "warn"
                    )
                    return
                end

                -- local excluded = false
                local filePath = vim.fn.expand("%:p")

                for _, pattern in ipairs(vim.g.format_on_save_exclude) do
                    local cmd = string.format(
                        '"%s" =~ glob2regpat("%s")',
                        filePath,
                        pattern
                    )
                    local result = vim.api.nvim_eval(cmd)
                    if result > 0 then
                        vim.notify(
                            "Format on save disabled for pattern: " .. pattern,
                            "warn"
                        )
                        return
                    end
                end

                vim.cmd("FormatWriteLock")
            end,
        })

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
                -- Disable it to rely on .editorconfig
                -- ["*"] = {
                --     require("formatter.filetypes.any").remove_trailing_whitespace,
                -- },
            },
        })
    end,
}
