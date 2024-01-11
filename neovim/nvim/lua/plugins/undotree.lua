return {
    "mbbill/undotree",
    init = function()
        -- set it to a permananet folder so I can undo across sessions
        vim.opt.undodir = os.getenv("HOME") .. "/.cache/undodir"
        vim.g.undotree_SetFocusWhenToggle = 1
        vim.opt.undofile = true
    end,
    config = function()
        vim.keymap.set(
            "n",
            "<leader>u",
            vim.cmd.UndotreeToggle,
            { desc = "Toggle undotree" }
        )
    end,
}
