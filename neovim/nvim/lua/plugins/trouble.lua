return {
    "folke/trouble.nvim",

    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },

    cmd = { "Trouble" },

    keys = {
        {
            "<leader>xx",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "Diagnostics (Trouble)",
            silent = true,
        },

        {
            "<leader>xd",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "Buffer Diagnostics (Trouble)",
            silent = true,
        },

        {
            "<leader>xw",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "Workspace Diagnostics (Trouble)",
            silent = true,
        },

        {
            "<leader>xq",
            "<cmd>Trouble qflist toggle<cr>",
            desc = "Quickfix List (Trouble)",
            silent = true,
        },

        {
            "<leader>xl",
            "<cmd>Trouble loclist toggle<cr>",
            desc = "Location List (Trouble)",
            silent = true,
        },

        {
            "[x",
            function()
                require("trouble").prev({ skip_groups = true, jump = true })
            end,
            desc = "Trouble previous",
            silent = true,
        },

        {
            "]x",
            function()
                require("trouble").next({ skip_groups = true, jump = true })
            end,
            desc = "Trouble next",
            silent = true,
        },
    },

    init = function()
        vim.keymap.set("n", "<leader>q", function()
            local line = vim.fn.getline(".")
            local trimmed = vim.trim(line)

            vim.fn.setqflist({
                {
                    filename = vim.fn.expand("%"),
                    lnum = vim.fn.line("."),
                    col = vim.fn.col("."),
                    text = trimmed,
                },
            }, "a")
        end, { desc = "Add current file to quickfix" })

        vim.keymap.set(
            "n",
            "<leader>qo",
            "<CMD>copen<CR>",
            {
                silent = true,
                noremap = true,
                desc = "Open the native quickFix list",
            }
        )

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "qf",
            callback = function(event)
                vim.keymap.set("n", "dd", function()
                    local qflist = vim.fn.getqflist()
                    if #qflist == 0 then
                        return
                    end

                    local line = vim.fn.line(".")
                    table.remove(qflist, line)
                    vim.fn.setqflist({}, " ", { items = qflist })

                    local new_count = #qflist

                    if new_count > 0 then
                        local new_line = math.min(line, new_count)
                        vim.api.nvim_win_set_cursor(0, { new_line, 0 })
                    end
                end, {
                    buffer = event.buf,
                    silent = true,
                    desc = "Delete entry in the quickfix list",
                })
            end,
        })
    end,

    config = function()
        require("trouble").setup({
            auto_refresh = false,
            -- The LSP base mode for:
            -- * lsp_definitions, lsp_references, lsp_implementations
            -- * lsp_type_definitions, lsp_declarations, lsp_command
            lsp_base = {
                params = {
                    -- I want to include current to fully circle around the results
                    include_current = true,
                },
            },
            -- modes = {
            --     lsp_incoming_calls = {
            --         auto_refresh = false,
            --     },
            -- },
        })
    end,
}
