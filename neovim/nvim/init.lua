-- https://lazy.folke.io/installation
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        lazyrepo,
        lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

require("00_version_and_env")
require("helpers")
require("vim-options")
require("remap")
require("commands")
require("autocmds")

vim.keymap.set(
    { "n" },
    "<leader>vl",
    "<CMD>Lazy<CR>",
    { desc = "Open Lazy plugin manager modal" }
)

require("lazy").setup("plugins", {
    change_detection = {
        notify = false,
    },
    -- colorscheme that will be used when installing plugins.
    install = { colorscheme = { "darcluar" } },
})
