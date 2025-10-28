return {
    root_dir = function(bufnr, on_dir)
        local bufname = vim.api.nvim_buf_get_name(bufnr) or ""

        if bufname:find("diffview") then
            return
        end

        local cwd = vim.uv.cwd()
        on_dir(cwd)
    end,
}
