--- @type vim.lsp.Config
return {
    before_init = function(_, client_config)
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
