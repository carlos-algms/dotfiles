return {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
        "pmizio/typescript-tools.nvim", -- added as dependency to check if refactoring will show on code-actions
    },
    config = function()
        require("lspsaga").setup({
            code_action = {
                show_server_name = true,
                -- it just shows gitsign options as code actions, I don't want that.
                -- extend_gitsigns = true,
            },
            definition = {
                width = 0.7,
                height = 0.6,
                keys = {
                    edit = "o",
                    vsplit = "v",
                    split = "s",
                },
            },
            finder = {
                left_width = 0.4,
                right_width = 0.4,
                layout = "float",
            },
            lightbulb = {
                enable = false,
                virtual_text = false, -- otherwise it shows twice, on the line number and on eol
            },
            rename = {
                in_select = false,
                keys = {
                    quit = "<esc>",
                },
            },
            outline = {
                layout = "float",
            },
            symbol_in_winbar = {
                enable = false,
            },
        })

        local diagnostic = require("lspsaga.diagnostic")

        -- disabled as it was constantly freezing and telling another request as in progress
        -- vim.keymap.set(
        --     { "n" },
        --     "K",
        --     ":Lspsaga hover_doc<CR>",
        --     { desc = "LSP [h]over [d]oc", silent = true }
        -- )

        vim.keymap.set(
            { "n", "v" },
            "gr",
            ":Lspsaga finder ref<CR>",
            { desc = "LSP [r]eferences" }
        )

        vim.keymap.set(
            { "n", "v" },
            "<leader>rn",
            ":Lspsaga rename<CR>",
            { desc = "LSP [r]ename", silent = true }
        )

        -- Disabling as it wasn't showing all the refactor options
        -- vim.keymap.set(
        --     { "n", "v" },
        --     "<leader>ca",
        --     ":Lspsaga code_action<CR>",
        --     { desc = "LSP [c]ode [a]ction", silent = true }
        -- )

        vim.keymap.set(
            { "n", "v" },
            "<leader>ro",
            ":Lspsaga outline<CR>",
            { desc = "LSP Outline", silent = true }
        )

        vim.keymap.set(
            { "n" },
            "<leader>pd",
            ":Lspsaga peek_definition<CR>",
            { desc = "LSP Peek Definition", silent = true }
        )

        vim.keymap.set(
            { "n" },
            "<leader>pt",
            ":Lspsaga peek_type_definition<CR>",
            { desc = "LSP Peek type definition", silent = true }
        )

        vim.keymap.set(
            { "n" },
            "<leader>pc",
            ":Lspsaga incoming_calls<CR>",
            { desc = "LSP Pick incoming calls", silent = true }
        )

        vim.keymap.set(
            "n",
            "]d",
            ":Lspsaga diagnostic_jump_next<CR>",
            { desc = "Go to next problem" }
        )

        vim.keymap.set(
            "n",
            "[d",
            ":Lspsaga diagnostic_jump_prev<CR>",
            { desc = "Go to previous problem" }
        )

        vim.keymap.set({ "n", "v" }, "]e", function()
            diagnostic:goto_next({
                severity = vim.diagnostic.severity.ERROR,
            })
        end, { desc = "Go to next Error" })

        vim.keymap.set({ "n", "v" }, "[e", function()
            diagnostic:goto_prev({
                severity = vim.diagnostic.severity.ERROR,
            })
        end, { desc = "Go to previous Error" })

        vim.keymap.set({ "n", "v" }, "]s", function()
            diagnostic:goto_next({
                severity = vim.diagnostic.severity.INFO,
            })
        end, { desc = "Go to next Spell/Info" })

        vim.keymap.set({ "n", "v" }, "[s", function()
            diagnostic:goto_prev({
                severity = vim.diagnostic.severity.INFO,
            })
        end, { desc = "Go to previous Spell/Info" })
    end,
}
