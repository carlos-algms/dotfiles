return {
    {
        "zbirenbaum/copilot.lua",

        cmd = "Copilot",

        event = "VeryLazy",

        enabled = vim.g.has_node,

        dependencies = {
            -- {
            --     "copilotlsp-nvim/copilot-lsp",
            --     init = function()
            --         vim.g.copilot_nes_debounce = 500
            --     end,
            -- },
        },

        opts = {
            -- it seems there's only 1 model available for autocompletion
            -- https://github.com/github/copilot.vim/issues/77#issuecomment-2848712690
            -- so I'll keep it commented out for now
            -- copilot_model = "copilot:claude-3.7-sonnet",
            suggestion = {
                enabled = true,
                auto_trigger = true,
                hide_during_completion = false,
                keymap = {
                    accept = "<C-l>",
                    accept_word = "<C-.>",
                    accept_line = "<C-j>",
                    next = "<A-]>",
                    prev = "<A-[>",
                    dismiss = "<A-h>",
                },
            },

            panel = { enabled = true },

            nes = {
                enabled = false,
                auto_trigger = false,
                keymap = {
                    accept_and_goto = "<C-y>",
                    accept = false,
                    dismiss = "<Esc>",
                },
            },

            filetypes = {
                yaml = true,
                markdown = true,
                gitcommit = true,
                gitrebase = true,
                snacks_picker_input = false,
            },

            -- Override should_attach to allow copilot in AgenticInput buffers
            -- AgenticInput uses buftype = "nofile" which copilot rejects by default
            should_attach = function(bufnr, bufname)
                local filetype = vim.bo[bufnr].filetype

                -- Allow AgenticInput specifically even though it has buftype = "nofile"
                if filetype == "AgenticInput" then
                    return true
                end

                -- Delegate to default behavior for all other buffers
                local default_should_attach =
                    require("copilot.config.should_attach").default
                return default_should_attach(bufnr, bufname)
            end,

            -- it either stopped working in node v22, or it was hiding the error messages before
            -- copilot_node_command = {
            --     "node",
            --     "--experimental-sqlite",
            -- },
        },
    },

    {
        "github/copilot.vim",
        event = { "VeryLazy" },

        enabled = false,

        init = function()
            vim.g.copilot_filetypes = {
                gitcommit = true,
                gitrebase = true,
                AgenticInput = true,
            }
        end,
    },
}
