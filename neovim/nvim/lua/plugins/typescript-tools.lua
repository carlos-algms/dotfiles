return {
    {
        "pmizio/typescript-tools.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },

        enabled = false, -- vim.g.has_node,

        ft = {
            "typescript",
            "typescriptreact",
            "javascript",
            "javascriptreact",
        },

        config = function(_, opts)
            local api = require("typescript-tools.api")

            opts.handlers = {
                ["textDocument/publishDiagnostics"] = api.filter_diagnostics({
                    80001, -- Ignore this might be converted to a ES export
                }),
            }

            require("typescript-tools").setup(opts)
        end,
        opts = {
            expose_as_code_action = "all",
            complete_function_calls = false,
            jsx_close_tag = {
                enable = true,
                filetypes = { "javascriptreact", "typescriptreact" },
            },
            on_attach = function(config, bufNr)
                vim.keymap.set(
                    { "n", "v" },
                    "<leader>io",
                    ":TSToolsOrganizeImports<CR>",
                    { desc = "Imports Organize", silent = true, buffer = bufNr }
                )

                vim.keymap.set(
                    { "n", "v" },
                    "<leader>is",
                    ":TSToolsSortImports<CR>",
                    { desc = "Imports Sort", silent = true, buffer = bufNr }
                )

                vim.keymap.set(
                    { "n", "v" },
                    "<leader>ir",
                    ":TSToolsRemoveUnusedImports<CR>",
                    {
                        desc = "Imports remove unused",
                        silent = true,
                        buffer = bufNr,
                    }
                )

                vim.keymap.set(
                    { "n", "v" },
                    "<leader>ia",
                    ":TSToolsAddMissingImports<CR>",
                    {
                        desc = "Imports Add All missing",
                        silent = true,
                        buffer = bufNr,
                    }
                )

                vim.keymap.set(
                    { "n", "v" },
                    "<leader>rf",
                    ":TSToolsRenameFile<CR>",
                    { desc = "Rename File", silent = true, buffer = bufNr }
                )
            end,
        },
    },

    {
        "dmmulroy/tsc.nvim",

        cmd = { "TSC" },

        opts = {
            auto_open_qflist = true,
            auto_close_qflist = true,
            auto_focus_qflist = false,
            use_trouble_qflist = true,
        },
        config = function(_, opts)
            require("tsc").setup(opts)
            require("tsc.utils").find_nearest_tsconfig = function()
                local tsconfig = vim.fn.findfile("tsconfig.json", ".;")

                if tsconfig ~= "" then
                    return { tsconfig }
                end

                tsconfig = vim.fn.findfile("jsconfig.json", ".;")

                if tsconfig ~= "" then
                    return { tsconfig }
                end

                return {}
            end
        end,
    },
}
