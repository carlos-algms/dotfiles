local function augroup(name)
    return vim.api.nvim_create_augroup("carlos_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup("highlight_yank"),
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({ higroup = "DiffText", timeout = 300 })
    end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("close_with_q"),
    pattern = {
        "checkhealth",
        "copilot.lua",
        "dap-float",
        "fugitiveblame",
        "git",
        "gitsigns-blame",
        "harpoon",
        "help",
        "lspinfo",
        "man",
        "neotest-output-panel",
        "neotest-output",
        "neotest-summary",
        "notify",
        "PlenaryTestPopup",
        "qf",
        "query",
        "spectre_panel",
        "startuptime",
        "tsplayground",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set(
            "n",
            "q",
            "<cmd>close<cr>",
            { buffer = event.buf, silent = true }
        )
    end,
})
