return {
    "knubie/vim-kitty-navigator",
    build = vim.g.is_ssh and nil or "cp ./*.py ~/.config/kitty/",
}
