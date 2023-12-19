-- enable auto-formatting on save
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    command = "FormatWriteLock",
})

-- Utilities for creating configurations
-- local util = require "formatter.util"

-- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
require("formatter").setup({
    -- All formatter configurations are opt-in
    filetype = {
        javascript = {
            require("formatter.filetypes.javascript").prettier,
        },
        javascriptreact = {
            require("formatter.filetypes.javascriptreact").prettier,
        },
        typescript = {
            require("formatter.filetypes.typescript").prettier,
        },
        typescriptreact = {
            require("formatter.filetypes.typescriptreact").prettier,
        },
        json = {
            require("formatter.filetypes.json").prettier,
        },
        html = {
            require("formatter.filetypes.html").prettier,
        },
        css = {
            require("formatter.filetypes.css").prettier,
        },
        scss = {
            require("formatter.filetypes.css").prettier,
        },
        markdown = {
            require("formatter.filetypes.markdown").prettier,
        },
        lua = {
            require("formatter.filetypes.lua").stylua,
        },
        yaml = {
            require("formatter.filetypes.yaml").prettier,
        },
        ["*"] = {
            require("formatter.filetypes.any").remove_trailing_whitespace,
        },
    },
})
