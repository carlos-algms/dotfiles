return {
    "folke/trouble.nvim",

    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "nvim-telescope/telescope.nvim",
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
        local config = require("telescope.config").values
        local actions = require("telescope.actions")

        local function send_all_to_quickfix_and_open_trouble(prompt_bufnr)
            actions.send_to_qflist(prompt_bufnr)
            vim.cmd("Trouble quickfix open")
        end

        local function selected_to_quickfix_and_open_trouble(prompt_bufnr)
            actions.send_selected_to_qflist(prompt_bufnr)
            vim.cmd("Trouble quickfix open")
        end

        local mappings = vim.F.if_nil(config.mappings, {})
        config.mappings = mappings
        local i = vim.F.if_nil(mappings.i, {})
        mappings.i = i
        local n = vim.F.if_nil(mappings.n, {})
        mappings.n = n

        -- Replace mappings to send to quickfix as Alt doesn't work well on Mac, and Alt + q is already mapped to <Esc>
        i["<C-S-q>"] = send_all_to_quickfix_and_open_trouble
        i["<C-q>"] = selected_to_quickfix_and_open_trouble

        n["<C-S-q>"] = send_all_to_quickfix_and_open_trouble
        n["<C-q>"] = selected_to_quickfix_and_open_trouble
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
