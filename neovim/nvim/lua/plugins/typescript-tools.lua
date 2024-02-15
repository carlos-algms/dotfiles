return {
    {
        "pmizio/typescript-tools.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
        opts = {
            expose_as_code_action = "all",
            complete_function_calls = { "all" },
            jsx_close_tag = {
                enable = true,
                filetypes = { "javascriptreact", "typescriptreact" },
            },
            on_attach = function(config, bufNr)
                vim.keymap.set(
                    { "n", "v" },
                    "<space>io",
                    ":TSToolsOrganizeImports<CR>",
                    { desc = "Imports Organize", silent = true, buffer = bufNr }
                )

                vim.keymap.set(
                    { "n", "v" },
                    "<space>is",
                    ":TSToolsSortImports<CR>",
                    { desc = "Imports Sort", silent = true, buffer = bufNr }
                )

                vim.keymap.set(
                    { "n", "v" },
                    "<space>ir",
                    ":TSToolsRemoveUnusedImports<CR>",
                    {
                        desc = "Imports remove unused",
                        silent = true,
                        buffer = bufNr,
                    }
                )

                vim.keymap.set(
                    { "n", "v" },
                    "<space>ia",
                    ":TSToolsAddMissingImports<CR>",
                    {
                        desc = "Imports Add All missing",
                        silent = true,
                        buffer = bufNr,
                    }
                )

                vim.keymap.set(
                    { "n", "v" },
                    "<space>rf",
                    ":TSToolsRenameFile<CR>",
                    { desc = "Rename File", silent = true, buffer = bufNr }
                )
            end,
        },
    },

    {
        "dmmulroy/tsc.nvim",
        opts = {
            auto_open_qflist = false,
        },
    },
}
