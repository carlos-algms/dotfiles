--- @type vim.lsp.Config
return {
    workspace_required = true,

    root_dir = function(bufnr, on_dir)
        -- I had to validate the buffer name because terraform-ls was crashing saying it couldn't read the file

        local bufname = vim.api.nvim_buf_get_name(bufnr) or ""

        if bufname == "" or vim.uv.fs_stat(bufname) == nil then
            return
        end

        local cwd = vim.uv.cwd()
        on_dir(cwd)
    end,
}
