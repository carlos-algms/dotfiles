vim.g.mapleader = " "

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Allows to move selected line of text up and down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Keeps the cursor on the center of the screen when running Ctrl + D or U
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Don't lose yank when pasting over a selected content (AKA: replace)
-- vim.keymap.set("x", "p", [["_dP]])
-- Don't lose yank when deleting selected content
-- vim.keymap.set("v", "d", [["_d]])

-- Keeps the cursor on the center when moving to next/prev search results
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- replace the selected content without losing the Yanked register
vim.keymap.set("x", "<leader>p", [["_dP]])

-- copy to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set("n", "Q", "<nop>")

-- replace all occurences of the word under the cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])