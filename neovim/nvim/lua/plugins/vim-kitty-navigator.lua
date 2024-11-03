return {
    "knubie/vim-kitty-navigator",
    build = not vim.g.is_ssh and "cp ./*.py ~/.config/kitty/" or nil,
}
