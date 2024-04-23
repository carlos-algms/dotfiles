local opt = vim.opt

opt.title = true
opt.titlelen = 0 -- do not shorten title
opt.titlestring = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
-- .. ' %{expand("%:.")}'

opt.nu = true
opt.relativenumber = true

opt.wrap = false
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true
opt.cursorline = true

opt.swapfile = false
opt.backup = false

opt.hlsearch = false
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true

opt.background = "dark"
opt.termguicolors = true

opt.colorcolumn = "80"
opt.scrolloff = 8 -- usually I use 10, I'm trying with 8 to have more lines visible
opt.signcolumn = "yes"
opt.isfname:append("@-@")
opt.splitright = true
opt.splitbelow = true

opt.updatetime = 50

-- opt.scriptencoding = "utf-8"
opt.fileencoding = "utf-8"
opt.encoding = "utf-8"

opt.diffopt = "iwhite,context:9999999,filler"
opt.foldenable = true
opt.foldmethod = "indent"
opt.foldlevel = 99
-- opt.fillchars = "diff: "
opt.fillchars = {
    foldopen = "",
    foldclose = "",
    -- fold = "⸱",
    fold = " ",
    foldsep = " ",
    -- diff = "╱",
    diff = " ",
    eob = " ",
}

opt.spelllang = { "en" }
opt.spell = false

opt.spelloptions = "camel,noplainbuffer"
opt.spellcapcheck = "" -- disable first letter capitalization check

opt.list = true
opt.listchars = {
    tab = "» ",
    trail = "·",
    -- space = ".",
    extends = "…",
    precedes = "…",
    nbsp = "␣",
    -- eol = "↲",
}

-- Allow to use grep and lgrep
opt.grepprg = "rg --vimgrep --no-heading --smart-case"

-- commented to show mode, as I removed it from the statusline
-- opt.showmode = false -- Dont show mode since we have a statusline

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0
