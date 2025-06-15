---@type vim.lsp.Config
return {
    root_markers = {
        "composer.json",
        ".git",
    },
    settings = {
        intelephense = {
            -- https://github.com/bmewburn/intelephense-docs/blob/master/installation.md
            telemetry = {
                enabled = false,
            },
            files = {
                maxSize = 1000000,
            },
            format = {
                enable = true,
                braces = "K&R", -- 1TBS
            },
        },
    },
}
