--- @type vim.lsp.Config
return {
    root_dir = function(bufnr, on_dir)
        local bufname = vim.api.nvim_buf_get_name(bufnr) or ""

        if bufname == "" or vim.uv.fs_stat(bufname) == nil then
            return
        end

        local cwd = vim.uv.cwd()
        on_dir(cwd)
    end,

    before_init = function(_, client_config)
        ---@diagnostic disable-next-line: inject-field
        client_config.settings.yaml.schemas =
            require("schemastore").yaml.schemas()
    end,

    settings = {
        redhat = { telemetry = { enabled = false } },
        yaml = {
            keyOrdering = false,
            format = {
                enable = false, -- conform and prettier are better
            },
            validate = true,
            schemaStore = {
                -- Must disable built-in schemaStore support to use schemas from SchemaStore.nvim plugin
                enable = false,
                -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
                url = "",
            },
        },
    },
}
