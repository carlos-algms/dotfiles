return {
    "nvim-pack/nvim-spectre",
    lazy = true,
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    keys = {
        {
            "<leader>S",
            '<cmd>lua require("spectre").toggle()<CR>',
            desc = "Toggle Spectre",
        },
        {
            "<leader>sw",
            '<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
            desc = "Search current word Spectre",
        },
        {
            "<leader>sw",
            '<esc><cmd>lua require("spectre").open_visual()<CR>',
            desc = "Search current word Spectre",
        },
        {
            "<leader>sp",
            '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
            desc = "Search on current file Spectre",
        },
    },
    opts = {
        is_block_ui_break = true, -- mapping backspace and enter key to avoid ui break
    },
}
