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
}
