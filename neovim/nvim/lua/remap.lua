local setKeymap = vim.keymap.set

setKeymap(
    { "n", "v" },
    "<leader>vi",
    "<CMD>Inspect<CR>",
    { desc = "Inspect current highlight" }
)

setKeymap(
    { "n", "v" },
    "<leader>vI",
    "<CMD>InspectTree<CR>",
    { desc = "Show Inspect Tree" }
)

setKeymap(
    { "n" },
    "<leader>vr",
    "<cmd>let &relativenumber = !&relativenumber<CR>",
    { desc = "Toggle relative line numbers globally" }
)

local wrap_state = {}
setKeymap({ "n" }, "<leader>vw", function()
    local buf_win = vim.api.nvim_get_current_win()
    if not vim.wo.wrap then
        wrap_state[buf_win] = {
            linebreak = vim.wo.linebreak,
            breakindent = vim.wo.breakindent,
        }
        vim.wo.wrap = true
        vim.wo.linebreak = true
        vim.wo.breakindent = true
    else
        local state = wrap_state[buf_win] or {}
        vim.wo.wrap = false
        vim.wo.linebreak = state.linebreak or false
        vim.wo.breakindent = state.breakindent or false
        wrap_state[buf_win] = nil
    end
end, { desc = "Toggle line wrapping locally" })

setKeymap("v", [[a"]], [[2i"]], { desc = "Select double quoted text" })
setKeymap("v", [[a']], [[2i']], { desc = "Select single quoted text" })

setKeymap({ "n", "v" }, "<C-.>", vim.lsp.buf.code_action, {
    desc = "LSP Code Action - nvim",
})

setKeymap(
    { "v" },
    "<Leader>cs",
    ":'<,'>!sort -f<CR>",
    { desc = "Sort selected lines" }
)

-- Tabs management
setKeymap(
    "n",
    "<leader>vtn",
    "<cmd>tabnew<cr>",
    { desc = "Open new tab", silent = true }
)
setKeymap(
    "n",
    "<leader>vtc",
    "<cmd>tabclose<cr>",
    { desc = "Close current tab", silent = true }
)
setKeymap(
    "n",
    "<leader>vts",
    "<cmd>tab split<cr>",
    { desc = "Open current buffer in a new tab", silent = true }
)

-- Keeps the cursor on the center of the screen when running Ctrl + D or U
setKeymap(
    "n",
    "<C-d>",
    "<C-d>zz",
    { desc = "Scroll down half page and center the cursor on the screen" }
)
setKeymap(
    "n",
    "<C-u>",
    "<C-u>zz",
    { desc = "Scroll up half page and center the cursor on the screen" }
)

setKeymap(
    { "n", "v" },
    "gf",
    "gF",
    { desc = "Go to file under cursor including line numbers" }
)

-- Keeps the cursor on the center when moving to next/prev search results
setKeymap("n", "n", "nzzzv")
setKeymap("n", "N", "Nzzzv")

-- copy to system clipboard
setKeymap(
    { "n", "v" },
    "<leader>y",
    [["+y]],
    { desc = "Copy to system clipboard" }
)

--

setKeymap("n", "Q", "<nop>")

setKeymap({ "i" }, "<C-j>", "<C-o>o", { desc = "Insert a new line bellow" })
setKeymap({ "i" }, "<C-k>", "<C-o>O", { desc = "Insert a new line above" })

-- better indenting
setKeymap("v", "<", "<gv")
setKeymap("v", ">", ">gv")

-- Resize windows
setKeymap(
    { "n", "i" },
    "<C-S-Up>",
    "<cmd>resize +2<cr>",
    { desc = "Increase window height" }
)

setKeymap(
    { "n", "i" },
    "<C-S-Down>",
    "<cmd>resize -2<cr>",
    { desc = "Decrease window height" }
)

setKeymap(
    { "n", "i" },
    "<C-S-Left>",
    "<cmd>vertical resize -2<cr>",
    { desc = "Decrease window width" }
)

setKeymap(
    { "n", "i" },
    "<C-S-Right>",
    "<cmd>vertical resize +2<cr>",
    { desc = "Increase window width" }
)

setKeymap(
    { "n", "i", "v" },
    "<D-s>",
    "<esc><cmd>update<cr>",
    { desc = "Save current buffer" }
)

setKeymap(
    { "n", "i" },
    "<D-w>",
    "<esc><cmd>close<cr>",
    { desc = "Close current buffer" }
)

-- Disabled to sue vim-kitty-navigator
-- set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
-- set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
-- set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
-- set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

setKeymap("n", "<Esc>", function()
    if vim.opt.hlsearch then
        vim.cmd.nohl()
    else
        vim.cmd("normal! <Esc>")
    end
end, { desc = "Clear search highlights or normal <Esc>" })
