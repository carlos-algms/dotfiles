-- Attach codebook spell checker to AgenticInput buffers.
-- vim.lsp.enable() skips buftype=nofile, so we start it manually.
vim.lsp.start(vim.lsp.config.codebook, { bufnr = 0 })
