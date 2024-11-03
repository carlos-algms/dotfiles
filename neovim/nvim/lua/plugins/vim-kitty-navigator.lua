return {
    "knubie/vim-kitty-navigator",
    build = !vim.g.is_ssh and "cp ./*.py ~/.config/kitty/" or nil,
}
