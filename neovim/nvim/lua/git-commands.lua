vim.api.nvim_create_user_command(
    "CompareToMaster",
    "DiffviewOpen origin/HEAD...HEAD --imply-local",
    { desc = "Compare current branch to master" }
)

vim.keymap.set(
    { "n" },
    "<leader>gcm",
    ":CompareToMaster<CR>",
    { silent = true, desc = "[C]ompare current branch to [m]aster" }
)
