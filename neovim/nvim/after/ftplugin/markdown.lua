-- Unmap the gO keymap set by the NeoVim runtime ftplugin
-- It was conflicting with Snacks
vim.keymap.del("n", "gO", { buffer = true })
