return {
    root_dir = function(bufnr, on_dir)
        local bufname = vim.api.nvim_buf_get_name(bufnr) or ""

        if bufname == "" or vim.uv.fs_stat(bufname) == nil then
            return
        end

        local cwd = vim.uv.cwd()
        on_dir(cwd)
    end,
}
