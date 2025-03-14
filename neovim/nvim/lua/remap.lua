vim.keymap.set(
    { "n", "v" },
    "<leader>vi",
    "<CMD>Inspect<CR>",
    { desc = "Inspect current highlight" }
)

vim.keymap.set(
    { "n", "v" },
    "<leader>vI",
    "<CMD>InspectTree<CR>",
    { desc = "Show Inspect Tree" }
)

vim.keymap.set(
    { "n" },
    "<leader>vr",
    "<cmd>let &relativenumber = !&relativenumber<CR>",
    { desc = "Toggle relative line numbers globally" }
)

vim.keymap.set({ "n" }, "<leader>vw", function()
    vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle line wrapping locally" })

vim.keymap.set("v", [[a"]], [[2i"]], { desc = "Select double quoted text" })
vim.keymap.set("v", [[a']], [[2i']], { desc = "Select single quoted text" })

-- Keeps the cursor on the center of the screen when running Ctrl + D or U
vim.keymap.set(
    "n",
    "<C-d>",
    "<C-d>zz",
    { desc = "Scroll down half page and center the cursor on the screen" }
)
vim.keymap.set(
    "n",
    "<C-u>",
    "<C-u>zz",
    { desc = "Scroll up half page and center the cursor on the screen" }
)

-- Keeps the cursor on the center when moving to next/prev search results
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- replace the selected content without losing the Yanked register
vim.keymap.set(
    "v",
    "<leader>p",
    [["_dP]],
    { desc = "Paste replacing selection without losing the Yanked register" }
)

-- Disabled, as I'm too used to `dd` and `D` to cut
-- vim.keymap.set(
--     "n",
--     "d",
--     [["_d]],
--     { desc = "delete without losing yanked register" }
-- )

-- vim.keymap.set(
--     "n",
--     "D",
--     [["_D]],
--     { desc = "delete without losing yanked register" }
-- )

-- vim.keymap.set(
--     "v",
--     "d",
--     [["_d]],
--     { desc = "Delete selection without losing Yanked register" }
-- )

-- vim.keymap.set(
--     "v",
--     "D",
--     [["_D]],
--     { desc = "Delete selection without losing Yanked register" }
-- )

-- copy to system clipboard
vim.keymap.set(
    { "n", "v" },
    "<leader>y",
    [["+y]],
    { desc = "Copy to system clipboard" }
)
vim.keymap.set(
    { "n", "v" },
    "<leader>Y",
    [["+yy]],
    { desc = "Copy entire line to system clipboard" }
)

-- Yank entire line
vim.keymap.set({ "n", "v" }, "Y", [[yy]], { desc = "Yank entire line" })

vim.keymap.set("n", "Q", "<nop>")

vim.keymap.set(
    { "n" },
    "]q",
    "<CMD>cnext<CR>",
    { desc = "Next item in the fix list" }
)

vim.keymap.set(
    { "n" },
    "[q",
    "<CMD>cprev<CR>",
    { desc = "Previous item in the fix list" }
)

vim.keymap.set(
    { "i" },
    "<C-j>",
    "<C-o>o",
    { desc = "Insert a new line bellow" }
)

vim.keymap.set({ "i" }, "<C-k>", "<C-o>O", { desc = "Insert a new line above" })

-- better indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

vim.keymap.set(
    { "n", "i" },
    "<C-S-Up>",
    "<cmd>resize +2<cr>",
    { desc = "Increase window height" }
)

vim.keymap.set(
    { "n", "i" },
    "<C-S-Down>",
    "<cmd>resize -2<cr>",
    { desc = "Decrease window height" }
)

vim.keymap.set(
    { "n", "i" },
    "<C-S-Left>",
    "<cmd>vertical resize -2<cr>",
    { desc = "Decrease window width" }
)

vim.keymap.set(
    { "n", "i" },
    "<C-S-Right>",
    "<cmd>vertical resize +2<cr>",
    { desc = "Increase window width" }
)

vim.keymap.set(
    { "n", "i", "v" },
    "<D-s>",
    "<esc><cmd>update<cr>",
    { desc = "Save current buffer" }
)

vim.keymap.set(
    { "n", "i" },
    "<D-w>",
    "<esc><cmd>close<cr>",
    { desc = "Close current buffer" }
)

-- Disabled to sue vim-kitty-navigator
-- vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
-- vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
-- vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
-- vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

vim.keymap.set("n", "<Esc>", function()
    if vim.opt.hlsearch then
        vim.cmd.nohl()
    else
        vim.cmd("normal! <Esc>")
    end
end, { desc = "Clear search highlights or normal <Esc>" })
