return {
    {
        "echasnovski/mini.move",
        version = "*",
        config = function()
            require("mini.move").setup({
                -- Module mappings. Use `''` (empty string) to disable one.
                mappings = {
                    -- Move selection in Visual mode
                    left = "˙", -- <Alt-h>
                    right = "¬", -- <Alt-l>
                    down = "∆", -- <Alt-j>
                    up = "˚", -- <Alt-k>

                    -- Move current line in Normal mode
                    line_left = "˙", -- <Alt-h>
                    line_right = "¬", -- <Alt-l>
                    line_down = "∆", -- <Alt-j>
                    line_up = "˚", -- <Alt-k>
                },
            })
        end,
    },
}
