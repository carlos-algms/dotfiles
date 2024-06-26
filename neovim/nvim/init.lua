local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

require("00_version_and_env")
require("helpers")
require("vim-options")
require("my-darcula-theme")
require("remap")
require("commands")
require("autocmds")

require("lazy").setup("plugins", {
    change_detection = {
        notify = false,
    },
})
