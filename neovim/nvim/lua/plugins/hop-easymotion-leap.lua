return {
    {
        -- this is the new hop.nvim fork, the original one has a disclaimer pointing to it
        "smoka7/hop.nvim",
        version = "*",
        enabled = true,
        opts = {
            -- I want to be precise when focusing on a specific word
            case_insensitive = false,
            -- keys = "etovxqpdygfblzhckisuran",
        },
        keys = {
            {

                "s",
                "<cmd>HopChar1AC<CR>",
                desc = "Hop to word forwards",
            },
            {
                "S",
                "<cmd>HopChar1BC<CR>",
                desc = "Hop to word backwards",
            },
            {
                "f",
                "<cmd>HopChar1CurrentLineAC<CR>",
                desc = "Hop to char forwards",
                remap = true,
            },
            {
                "F",
                "<cmd>HopChar1CurrentLineBC<CR>",
                desc = "Hop to char backwards",
                remap = true,
            },
            {
                "t",
                function() -- I had to use a fn because of the offset
                    local hop = require("hop")
                    local HintDirection = require("hop.hint").HintDirection
                    hop.hint_char1({
                        direction = HintDirection.AFTER_CURSOR,
                        current_line_only = true,
                        hint_offset = -1,
                    })
                end,
                desc = "Go to before char forwards",
                remap = true,
            },
            {
                "T",
                function() -- I had to use a fn because of the offset
                    local hop = require("hop")
                    local HintDirection = require("hop.hint").HintDirection
                    hop.hint_char1({
                        direction = HintDirection.BEFORE_CURSOR,
                        current_line_only = true,
                        hint_offset = 1,
                    })
                end,
                desc = "Go to before char backwards",
            },
        },
    },
    {
        "easymotion/vim-easymotion",
        enabled = false,
        init = function()
            vim.g.EasyMotion_smartcase = true
            vim.g.EasyMotion_do_mapping = false
            -- vim.g.EasyMotion_inc_highlight = false
            vim.g.EasyMotion_disable_two_key_combo = true
            -- vim.g.EasyMotion_keys = "abcdefhjkmnoprstuvwxyz;"
            -- https://github.com/easymotion/vim-easymotion/pull/440#issuecomment-727844125

            -- it stops the LSP from showing errors, but the process has to start again, I didn't measure, but it seems unnecessary.
            -- vim.cmd([[ autocmd User EasyMotionPromptBegin silent! LspStop ]])
            -- vim.cmd([[ autocmd User EasyMotionPromptEnd silent! LspStart ]])
        end,
        keys = {
            {
                -- "∑", -- alt+w
                "s",
                "<Plug>(easymotion-w)",
                mode = { "n" },
                desc = "EasyMotion onwards",
            },
            {
                -- "∫", -- alt + b
                "S",
                "<Plug>(easymotion-b)",
                mode = { "n" },
                desc = "EasyMotion backwards",
            },
            {
                "f",
                "<Plug>(easymotion-wl)",
                mode = { "n" },
                desc = "EasyMotion backwards",
            },
            {
                "F",
                "<Plug>(easymotion-bl)",
                mode = { "n" },
                desc = "EasyMotion backwards",
            },
        },
    },
    {
        "ggandor/leap.nvim",
        enabled = false,
        event = "VeryLazy",
        -- copy from https://www.lazyvim.org/extras/editor/leap
        keys = {
            { "s", mode = { "n" }, desc = "Leap forward to" },
            { "S", mode = { "n" }, desc = "Leap backward to" },
            { "gs", mode = { "n" }, desc = "Leap from windows" },
        },
        config = function(_, opts)
            local leap = require("leap")
            for k, v in pairs(opts) do
                leap.opts[k] = v
            end

            -- it shows an error at the startup but it fixes the conflict with surround.nvim
            leap.create_default_mappings(true)
            -- leap.add_default_mappings(true)
            -- vim.keymap.del({ "x", "o" }, "x")
            -- vim.keymap.del({ "x", "o" }, "X")

            -- Hack to hide cursor on auto jump
            vim.api.nvim_create_autocmd("User", {
                callback = function()
                    vim.cmd.hi("Cursor", "blend=100")
                    vim.opt.guicursor:append({ "a:Cursor/lCursor" })
                end,
                pattern = "LeapEnter",
            })

            vim.api.nvim_create_autocmd("User", {
                callback = function()
                    vim.cmd.hi("Cursor", "blend=0")
                    vim.opt.guicursor:remove({ "a:Cursor/lCursor" })
                end,
                pattern = "LeapLeave",
            })
        end,
    },
}
