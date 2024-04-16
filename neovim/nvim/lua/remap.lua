vim.g.mapleader = " "

vim.keymap.set(
    "n",
    "<leader>pv",
    vim.cmd.Ex,
    { desc = "Open nvim default file explorer" }
)

-- Allows to move selected line of text up and down
vim.keymap.set(
    "v",
    "J",
    ":m '>+1<CR>gv=gv",
    { desc = "Move selected line down" }
)
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected line up" })

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

-- Don't lose yank when pasting over a selected content (AKA: replace)
-- vim.keymap.set("x", "p", [["_dP]])
-- Don't lose yank when deleting selected content
-- vim.keymap.set("v", "d", [["_d]])

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

-- replace all occurrences of the word under the cursor
-- vim.keymap.set(
--     "n",
--     "<leader>s",
--     [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
--     { desc = "Replace all occurrences of the word under the cursor" }
-- )

-- window management
vim.keymap.set("n", "<leader>w", "<C-w>", { desc = "Ctrl + w replacement" })

vim.keymap.set(
    { "n", "v", "i", "x", "s", "c" },
    "œ",
    "<Esc>",
    { desc = "Alt + q - Same as <Esc>" }
)

vim.keymap.set(
    { "n" },
    "]q",
    ":cnext<CR>",
    { desc = "Next item in the fix list" }
)

vim.keymap.set(
    { "n" },
    "[q",
    ":cprev<CR>",
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

-- Disabled to test autopairs plugin
-- -- adding vanilla auto-close for quotes and brackets
-- vim.keymap.set("i", "'", "''<Left>", { desc = "auto close single quotes" })
-- vim.keymap.set("i", '"', '""<Left>', { desc = "auto close double quotes" })
-- vim.keymap.set("i", "[", "[]<Left>", { desc = "auto close square brackets" })
-- vim.keymap.set("i", "{", "{}<Left>", { desc = "auto close curly brackets" })
-- vim.keymap.set(
--     "i",
--     "{<CR>",
--     "{<CR>}<ESC>O",
--     { desc = "auto close curly brackets new line" }
-- )

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
    { "n", "i" },
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

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })

vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })

vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })

vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
