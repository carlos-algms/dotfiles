
-- https://github.com/vscode-neovim/vscode-neovim/wiki/Plugins#vim-sandwich
-- suggested by nvim-vscode author
if vim.g.vscode then
    vim.cmd.highlight("OperatorSandwichBuns guifg='#aa91a0' gui=underline ctermfg=172 cterm=underline")
    vim.cmd.highlight("OperatorSandwichChange guifg='#edc41f' gui=underline ctermfg='yellow' cterm=underline")
    vim.cmd.highlight("OperatorSandwichAdd guibg='#b1fa87' gui=none ctermbg='green' cterm=none")
    vim.cmd.highlight("OperatorSandwichDelete guibg='#cf5963' gui=none ctermbg='red' cterm=none")
end
