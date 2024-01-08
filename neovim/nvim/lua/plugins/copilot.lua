return {
    "github/copilot.vim",
    config = function()
        vim.g.copilot_filetypes = {
            yml = true,
            yaml = true,
            markdown = true,
        }
    end,
}
