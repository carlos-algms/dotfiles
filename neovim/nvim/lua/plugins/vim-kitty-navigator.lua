return {
    "knubie/vim-kitty-navigator",
    -- Disabled to avoid exploit, check the files before copying them
    -- build = not vim.g.is_ssh and "cp ./*.py ~/.config/kitty/" or nil,
    config = function()
        if vim.g.is_ssh then
            vim.fn.system("kitten @ set-user-vars IS_NVIM=true")

            vim.api.nvim_create_autocmd("VimLeavePre", {
                group = vim.api.nvim_create_augroup(
                    "vim-kitty-navigator",
                    { clear = true }
                ),
                callback = function()
                    vim.fn.system("kitten @ set-user-vars IS_NVIM=false")
                end,
            })
        end
    end,
}
