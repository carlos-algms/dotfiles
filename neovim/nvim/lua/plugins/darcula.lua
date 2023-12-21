return {
    "doums/darcula",
    as = "darcula",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd.colorscheme("darcula")
        vim.opt.termguicolors = true
        vim.o.background = "dark"
    end,
}
