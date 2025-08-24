--- @type vim.lsp.Config
return {
    root_markers = {
        "tsconfig.json",
        "jsconfig.json",
        "package.json",
        ".git",
    },

    filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
    },

    settings = (function()
        --- @module 'lspconfig'
        --- @type lspconfig.Config
        ---@diagnostic disable-next-line: missing-fields
        local settings = {
            -- https://github.com/yioneko/vtsls/blob/main/packages/service/configuration.schema.json
            vtsls = {
                enableMoveToFileCodeAction = true,
                autoUseWorkspaceTsdk = true,
                experimental = {
                    maxInlayHintLength = 30,
                    completion = {
                        enableServerSideFuzzyMatch = true,
                    },
                },
                typescript = {
                    format = {
                        indentSize = 2,
                    },
                },
            },

            typescript = {
                tsserver = {
                    -- fix constant crashing in large projects
                    -- https://github.com/microsoft/vscode/issues/202894#issuecomment-1901245615
                    maxTsServerMemory = 8192,

                    pluginPaths = {
                        "typescript-plugin-css-modules",
                    },
                },
                updateImportsOnFileMove = {
                    enabled = "always",
                },
                suggest = {
                    completeFunctionCalls = false,
                },
                inlayHints = {
                    enumMemberValues = { enabled = true },
                    functionLikeReturnTypes = {
                        enabled = false,
                    },
                    parameterNames = {
                        enabled = "literals",
                    },
                    parameterTypes = { enabled = true },
                    propertyDeclarationTypes = {
                        enabled = true,
                    },
                    variableTypes = { enabled = false },
                },
                preferences = {
                    importModuleSpecifier = "shortest",
                    preferTypeOnlyAutoImports = true,
                    quoteStyle = "single",
                },
            },
        }

        settings.javascript = vim.tbl_deep_extend(
            "force",
            {},
            settings.typescript,
            settings.javascript or {}
        )

        settings.vtsls.javascript = vim.tbl_deep_extend(
            "force",
            {},
            settings.vtsls.typescript,
            settings.vtsls.javascript or {}
        )
        return settings
    end)(),

    on_attach = function(client, bufNr)
        require("helpers.lsp_helpers").onLspAttach(client, bufNr)

        local vtslsCommands = require("vtsls").commands

        --- @param keys string
        --- @param func function
        --- @param desc string
        local function tsKeymap(keys, func, desc)
            vim.keymap.set({ "n", "v" }, keys, func, {
                desc = desc,
                silent = true,
                buffer = bufNr,
            })
        end

        tsKeymap("<leader>io", function()
            vtslsCommands.organize_imports(bufNr)
        end, "TS Imports Organize")

        tsKeymap("<leader>is", function()
            vtslsCommands.sort_imports(bufNr)
        end, "TS Imports Sort")

        tsKeymap("<leader>ir", function()
            vtslsCommands.remove_unused_imports(bufNr)
        end, "TS Imports remove unused")

        tsKeymap("<leader>ia", function()
            vtslsCommands.add_missing_imports(bufNr)
        end, "TS Imports Add All missing")

        tsKeymap("<leader>rf", function()
            vtslsCommands.rename_file(bufNr)
        end, "TS Rename File")

        -- tsKeymap("<leader>ct", function()
        --     vtslsCommands.select_ts_version(bufNr)
        -- end, "TS Select Typescript Version")

        tsKeymap("gD", function()
            vtslsCommands.goto_source_definition(nil)
        end, "TS Go to source definition")
    end,
}
