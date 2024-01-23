return {
    "akinsho/toggleterm.nvim",
    version = "*",
    -- Disabled it as Kitty have the same functionality
    -- with the benefit of run outside of Neovim, so no drawbacks
    -- I might enable it again to use on SSH sessions, as it will open on the remote's cwd
    enabled = false,
    opts = {
        open_mapping = [[<C-`>]],
    },
    config = function(_, pluginOpts)
        require("toggleterm").setup(pluginOpts)

        function _G.set_terminal_keymaps()
            local opts = { buffer = 0 }
            vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
            vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
            vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
            vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
            vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
            vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
            vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
        end

        -- if you only want these mappings for toggle term use term://*toggleterm#* instead
        vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
    end,
}
