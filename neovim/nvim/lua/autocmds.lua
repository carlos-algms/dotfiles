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

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
    group = augroup("resize_splits"),
    callback = function()
        local current_tab = vim.fn.tabpagenr()
        vim.cmd("tabdo wincmd =")
        vim.cmd("tabnext " .. current_tab)
    end,
})

-- vim.defer_fn(function()
--     vim.cmd(
--         [[ au TextYankPost * silent! lua vim.highlight.on_yank({ higroup="DiffText", timeout=350 }) ]]
--     )
-- end, 100)

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("close_with_q"),
    pattern = {
        "checkhealth",
        "copilot.lua",
        "dap-float",
        "fugitiveblame",
        "git",
        "harpoon",
        "help",
        "lspinfo",
        "man",
        "neotest-output",
        "neotest-output-panel",
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

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "docker-compose.yml", "docker-compose.yaml" },
    command = "set filetype=yaml.docker-compose",
})
