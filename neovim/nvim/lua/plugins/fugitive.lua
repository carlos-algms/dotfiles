local set = vim.keymap.set
local loaded = false

local function load_fugitive()
    if loaded then
        return
    end
    loaded = true

    vim.pack.add({
        "https://github.com/tpope/vim-fugitive",
    })
end

vim.api.nvim_create_user_command("UndoLastCommit", function()
    load_fugitive()
    vim.cmd("Git reset --soft HEAD~")
end, {})

vim.api.nvim_create_user_command("GitCommit", function()
    load_fugitive()
    vim.cmd("tab Git commit")
end, {})

-- Keymaps that trigger lazy load
local function lazy(cmd)
    return function()
        load_fugitive()
        vim.cmd(cmd)
    end
end

set("n", "<leader>g<C-p>", lazy("Git push -u"), { desc = "Git Push" })
set("n", "<leader>g<C-l>", lazy("Git pull --rebase --autostash"), { desc = "Git pull --rebase --autostash" })
set("n", "<leader>gd", lazy("Gvdiffsplit!"), { desc = "Show git diff for current file" })
set("n", "<leader>gb", lazy("Git blame"), { desc = "Git Blame" })
set("n", "<leader>gU", lazy("UndoLastCommit"), { desc = "Git Undo last commit" })

set({ "n", "v" }, "<leader>gC", function()
    load_fugitive()
    local defaultName = "cgomes/"
    vim.ui.input({
        prompt = "Branch name: ",
        default = defaultName,
    }, function(newBranchName)
        if
            not newBranchName
            or newBranchName == ""
            or newBranchName == defaultName
        then
            vim.notify("Not creating a branch", "info")
            return
        end

        vim.cmd("Git checkout -b " .. newBranchName)
    end)
end, { desc = "Git Create Branch" })
