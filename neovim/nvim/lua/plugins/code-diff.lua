local set = vim.keymap.set

vim.pack.add({
    "https://github.com/esmuellert/codediff.nvim",
})

require("codediff").setup({
    explorer = {
        position = "bottom",
        initial_focus = "modified", -- Initial focus: "explorer", "original", or "modified"
    },

    -- Keymaps in diff view
    keymaps = {
        view = {
            next_hunk = ")",
            prev_hunk = "(",
            next_file = "J",
            prev_file = "K",
            stage_hunk = "=",
            unstage_hunk = "-",
            toggle_stage = ";",
        },
    },
})

set(
    "n",
    "<leader>gs",
    ":CodeDiff<CR>",
    { desc = "Git status - code-diff.nvim", silent = true }
)
set(
    "n",
    "<leader>gcm",
    ":CodeDiff origin/HEAD...<CR>",
    { desc = "Git compare to main - code-diff.nvim", silent = true }
)
set(
    "n",
    "<leader>gh",
    ":CodeDiff history HEAD~20 %<CR>",
    { desc = "Git history current file - code-diff.nvim", silent = true }
)
set(
    "n",
    "<leader>gH",
    ":CodeDiff history<CR>",
    { desc = "Git commit history- code-diff.nvim", silent = true }
)

vim.api.nvim_create_autocmd("User", {
    pattern = "CodeDiffOpen",
    callback = function()
        vim.t.codediff_open = true
    end,
})

set("n", "cc", function()
    if vim.t.codediff_open then
        vim.cmd("GitCommit")
    else
        vim.api.nvim_feedkeys("cc", "n", false)
    end
end, { desc = "Git commit from CodeDiff (or default cc)" })
