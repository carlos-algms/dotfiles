vim.opt.nu = true

vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.smartcase = true

vim.opt.background = "dark"
vim.opt.termguicolors = true

vim.opt.colorcolumn = "80"
vim.opt.scrolloff = 99
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.updatetime = 50

vim.scriptencoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.encoding = "utf-8"

vim.opt.diffopt = "iwhite,context:9999999"
vim.opt.foldenable = false

vim.opt.spelllang = "en_us"
vim.opt.spell = true

vim.opt.listchars = {
    tab = "» ",
    trail = "·",
    -- space = ".",
    extends = "…",
    precedes = "…",
    nbsp = "␣",
    -- eol = "↲",
}
vim.opt.list = true
