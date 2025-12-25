vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- known issue - :Inspect is not working
vim.hl = vim.highlight

require("00_version_and_env")
require("helpers")

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

require("vim-options")
require("shada-manager")
require("remap")
require("commands")
require("autocmds")
require("jump_to_node")
require("eslint")

vim.keymap.set(
    { "n" },
    "<leader>vl",
    "<CMD>Lazy<CR>",
    { desc = "Open Lazy plugin manager modal" }
)

local function is_user_thread_limited()
    local user = vim.fn.getenv("USER")
    local thread_limited_users = vim.fn.getenv("THREAD_LIMITED_USERS")

    if not thread_limited_users or thread_limited_users == vim.NIL then
        return false
    end

    for limited_user in string.gmatch(thread_limited_users, "([^%s]+)") do
        if limited_user == user then
            return true
        end
    end
    return false
end

-- https://lazy.folke.io/configuration
require("lazy").setup("plugins", {
    change_detection = {
        notify = false,
    },
    rocks = {
        enabled = true,
        -- use hererocks to install luarocks?
        -- set to `nil` to use hererocks when luarocks is not found
        -- set to `true` to always use hererocks
        -- set to `false` to always use luarocks
        hererocks = nil,
    },
    -- colorscheme that will be used when installing plugins.
    install = { colorscheme = { "darcluar" } },
    -- as in the Docs + make it work in Shared Hosts like GoDaddy, where they limit the number of processes and threads
    concurrency = jit.os:find("Windows")
            and (vim.loop.available_parallelism() * 2)
        or (is_user_thread_limited() and 1 or nil),
})
