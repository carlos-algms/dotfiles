return {
    "mbbill/undotree",

    keys = {
        {
            "<leader>u",
            "<cmd>UndotreeToggle<CR>",
            desc = "Toggle undotree",
        },
    },

    init = function()
        -- set it to a permanent folder so I can undo across sessions
        vim.opt.undodir = os.getenv("HOME") .. "/.cache/undodir"
        vim.g.undotree_SetFocusWhenToggle = 1
        vim.opt.undofile = true
    end,
}
