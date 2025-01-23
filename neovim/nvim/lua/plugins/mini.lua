return {
    {
        "echasnovski/mini.move",
        version = "*",
        config = function()
            require("mini.move").setup({
                -- Module mappings. Use `''` (empty string) to disable one.
                mappings = {
                    -- Move selection in Visual mode
                    left = "<A-h>",
                    right = "<A-l>",
                    down = "<A-j>",
                    up = "<A-k>",

                    -- Move current line in Normal mode
                    line_left = "<A-h>",
                    line_right = "<A-l>",
                    line_down = "<A-j>",
                    line_up = "<A-k>",
                },
            })
        end,
    },
}
