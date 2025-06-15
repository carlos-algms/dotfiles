---@type vim.lsp.Config
return {
    on_attach = function(...)
        require("helpers.lsp_helpers").enableLspFeatures(...)
    end,
    before_init = function(_, client_config)
        client_config.settings.json.schemas =
            require("schemastore").json.schemas()
    end,
    settings = {
        json = {
            validate = { enable = true },
        },
    },
}
