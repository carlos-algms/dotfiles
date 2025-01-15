local helpers = {}

local M = {
    {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
            library = {
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = "luvit-meta/library", words = { "vim%.uv" } },
            },
        },
    },

    {
        "williamboman/mason.nvim",

        dependencies = {
            { "williamboman/mason-lspconfig.nvim" },
            { "neovim/nvim-lspconfig" },
            { "hrsh7th/nvim-cmp" }, -- adding it here to wait for it to config
            { "hrsh7th/cmp-nvim-lsp" },
            { "WhoIsSethDaniel/mason-tool-installer.nvim" },
            { "b0o/schemastore.nvim" },

            { "yioneko/nvim-vtsls" },
        },

        init = function()
            vim.filetype.add({
                extension = {
                    zsh = "sh",
                    sh = "sh", -- force sh-files with zsh-shebang to still get sh as filetype
                },
                filename = {
                    [".zshrc"] = "sh",
                    [".zprofile"] = "sh",
                    [".zshenv"] = "sh",
                    ["composer.lock"] = "json",
                    ["phpstan.neon"] = "yaml",
                },
                pattern = {
                    ["%.vscode/.*%.json"] = "jsonc",
                },
            })

            vim.keymap.set(
                { "n" },
                "<leader>vm",
                "<CMD>Mason<CR>",
                { desc = "Open Mason modal" }
            )
        end,

        config = function()
            -- https://github.com/neovim/nvim-lspconfig#suggested-configuration
            -- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/you-might-not-need-lsp-zero.md

            -- note: diagnostics are not exclusive to lsp servers
            -- so these can be global keybindings
            vim.keymap.set(
                "n",
                "gl",
                vim.diagnostic.open_float,
                { desc = "Open problems in a floating window" }
            )

            helpers.setupLspRoundedBorders()

            require("mason").setup()
            local tables = require("helpers.tables")

            local ensureToolsInstalled = {
                "shfmt",
                "stylua",
                -- "black",
            }

            local ensureLspInstalled = {
                "bashls",
                "lua_ls",
            }

            if vim.g.has_node then
                tables.deep_extend(ensureToolsInstalled, { "prettier" })
                tables.deep_extend(ensureLspInstalled, { "jsonls" })
            end

            if not vim.g.is_ssh then
                if vim.g.has_node then
                    tables.deep_extend(
                        ensureToolsInstalled,
                        { "js-debug-adapter" }
                    )

                    tables.deep_extend(ensureLspInstalled, {
                        "vtsls",
                        "html",
                        "cssls",
                        -- "phpactor",
                        "intelephense",
                        "emmet_language_server",
                    })
                end
            end

            if vim.fn.executable("go") == 1 then
                tables.deep_extend(ensureLspInstalled, { "gopls" })
                -- tables.deep_extend(
                --     ensureToolsInstalled,
                --     { "goimports-reviser" }
                -- )
            end

            require("mason-tool-installer").setup({
                ensure_installed = ensureToolsInstalled,
            })

            local masonLspConfig = require("mason-lspconfig")
            local lspConfig = require("lspconfig")
            local util = require("lspconfig.util")

            require("lspconfig.configs").vtsls = require("vtsls").lspconfig

            local all_lsp_capabilities =
                require("cmp_nvim_lsp").default_capabilities(
                    vim.lsp.protocol.make_client_capabilities()
                )

            local disabledLspServers = {
                "ts_ls",
                "tsserver",
                -- "vtsls",
            }

            masonLspConfig.setup({
                ensure_installed = ensureLspInstalled,
                automatic_installation = false,
                handlers = {
                    function(server_name)
                        -- just make sure they are disabled, as I'm using typescript-tools.nvim
                        if
                            vim.tbl_contains(disabledLspServers, server_name)
                        then
                            return false
                        end

                        lspConfig[server_name].setup({
                            capabilities = all_lsp_capabilities,
                            on_attach = helpers.onLspAttach,
                        })
                    end,

                    vtsls = function()
                        --- @type lspconfig.Config
                        ---@diagnostic disable-next-line: missing-fields
                        local vtsls_config = {
                            capabilities = all_lsp_capabilities,
                            root_dir = function(pattern)
                                local root = util.root_pattern(
                                    "tsconfig.json",
                                    "jsconfig.json",
                                    "package.json",
                                    ".git"
                                )(pattern)

                                if not root then
                                    root = vim.fn.getcwd()
                                end

                                ---@diagnostic disable-next-line: redundant-return-value
                                return root
                            end,
                            filetypes = {
                                "javascript",
                                "javascriptreact",
                                "javascript.jsx",
                                "typescript",
                                "typescriptreact",
                                "typescript.tsx",
                            },
                            -- https://github.com/yioneko/vtsls/blob/541b52a341a740b1b2d1b4ae85f168dbb3ac6d25/packages/service/configuration.schema.json#L1212
                            settings = {
                                complete_function_calls = true,
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
                                    updateImportsOnFileMove = {
                                        enabled = "always",
                                    },
                                    suggest = {
                                        completeFunctionCalls = true,
                                    },
                                    inlayHints = {
                                        enumMemberValues = { enabled = true },
                                        functionLikeReturnTypes = {
                                            enabled = true,
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
                                },
                            },
                            on_attach = function(client, bufNr)
                                helpers.onLspAttach(client, bufNr)

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

                                tsKeymap("<leader>ct", function()
                                    vtslsCommands.select_ts_version(bufNr)
                                end, "TS Select Typescript Version")

                                tsKeymap("gD", function()
                                    vtslsCommands.goto_source_definition(nil)
                                end, "TS Go to source definition")
                            end,
                        }

                        vtsls_config.settings.javascript = vim.tbl_deep_extend(
                            "force",
                            {},
                            vtsls_config.settings.typescript,
                            vtsls_config.settings.javascript or {}
                        )

                        vtsls_config.settings.vtsls.javascript =
                            vim.tbl_deep_extend(
                                "force",
                                {},
                                vtsls_config.settings.vtsls.typescript,
                                vtsls_config.settings.vtsls.javascript or {}
                            )

                        lspConfig.vtsls.setup(vtsls_config)
                    end,

                    jsonls = function()
                        lspConfig.jsonls.setup({
                            capabilities = all_lsp_capabilities,
                            on_attach = helpers.enableLspFeatures,
                            -- lazy-load schemastore when needed - https://www.lazyvim.org/extras/lang/json#nvim-lspconfig
                            on_new_config = function(new_config)
                                new_config.settings.json.schemas =
                                    vim.tbl_deep_extend(
                                        "force",
                                        new_config.settings.json.schemas or {},
                                        require("schemastore").json.schemas()
                                    )
                            end,
                            settings = {
                                json = {
                                    validate = { enable = true },
                                },
                            },
                        })
                    end,

                    yamlls = function()
                        lspConfig.yamlls.setup({
                            capabilities = all_lsp_capabilities,
                            on_attach = helpers.enableLspFeatures,
                            -- lazy-load schemastore when needed
                            on_new_config = function(new_config)
                                new_config.settings.yaml.schemas =
                                    vim.tbl_deep_extend(
                                        "force",
                                        new_config.settings.yaml.schemas or {},
                                        require("schemastore").yaml.schemas()
                                    )
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
                        })
                    end,

                    lua_ls = function()
                        lspConfig.lua_ls.setup({
                            capabilities = all_lsp_capabilities,
                            on_attach = helpers.onLspAttach,
                            settings = {
                                Lua = {
                                    telemetry = { enable = false },
                                    runtime = {
                                        version = "LuaJIT",
                                    },
                                    diagnostics = {
                                        globals = { "vim", "get_args" },
                                    },
                                    workspace = {
                                        library = {
                                            vim.env.VIMRUNTIME,
                                        },
                                    },
                                },
                            },
                        })
                    end,

                    phpactor = function()
                        return false
                        -- lspConfig.phpactor.setup({
                        --     capabilities = all_lsp_capabilities,
                        --     on_attach = helpers.onLspAttach,
                        --     init_options = {
                        --         ["language_server_phpstan.enabled"] = false,
                        --         ["language_server_psalm.enabled"] = false,
                        --     },
                        --     root_dir = function(pattern)
                        --         local cwd = vim.uv.cwd()
                        --         local root = util.root_pattern(
                        --             "composer.json",
                        --             ".git",
                        --             ".phpactor.json",
                        --             ".phpactor.yml"
                        --         )(pattern)
                        --
                        --         return root
                        --
                        --         -- return util.path.is_descendant(cwd, root)
                        --         --         and cwd
                        --         --     or root
                        --     end,
                        -- })
                    end,

                    intelephense = function()
                        lspConfig.intelephense.setup({
                            capabilities = all_lsp_capabilities,
                            on_attach = helpers.onLspAttach,
                            root_dir = function(pattern)
                                local root = util.root_pattern(
                                    "composer.json",
                                    ".git"
                                )(pattern)

                                return root
                            end,
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
                        })
                    end,

                    eslint = function()
                        lspConfig.eslint.setup({
                            capabilities = all_lsp_capabilities,
                            on_attach = helpers.enableLspFeatures,
                            root_dir = function(pattern)
                                local root = util.root_pattern(
                                    "eslint.config.js",
                                    "eslint.config.mjs",
                                    "eslint.config.ts",
                                    ".eslintrc.js",
                                    ".eslintrc.mjs",
                                    ".eslintrc.json",
                                    ".eslintrc.yaml",
                                    ".eslintrc.yml",
                                    ".eslintrc"
                                )(pattern)

                                return root
                            end,
                            settings = {
                                options = {
                                    -- Disabled, as if a config file is found, it won't start. and this is different depending o eslint version
                                    -- overrideConfig = {
                                    --     ignores = {
                                    --         "**.vscode**",
                                    --         "**/nvm/**",
                                    --         "**/node_modules/**",
                                    --         "**/lib/**",
                                    --         "**/dist/**",
                                    --         "**/public/**",
                                    --         "**/build/**",
                                    --     },
                                    -- },
                                },
                            },
                        })
                    end,

                    gopls = function()
                        lspConfig.gopls.setup({
                            capabilities = all_lsp_capabilities,
                            on_attach = function(client, bufNr)
                                helpers.onLspAttach(client, bufNr)

                                if
                                    not client.server_capabilities.semanticTokensProvider
                                then
                                    local semantic =
                                        client.config.capabilities.textDocument.semanticTokens
                                    client.server_capabilities.semanticTokensProvider =
                                        {
                                            full = true,
                                            legend = {
                                                tokenTypes = semantic.tokenTypes,
                                                tokenModifiers = semantic.tokenModifiers,
                                            },
                                            range = true,
                                        }
                                end
                            end,
                            settings = {
                                gopls = {
                                    gofumpt = true,
                                    codelenses = {
                                        gc_details = false,
                                        generate = true,
                                        regenerate_cgo = true,
                                        run_govulncheck = true,
                                        test = true,
                                        tidy = true,
                                        upgrade_dependency = true,
                                        vendor = true,
                                    },
                                    hints = {
                                        assignVariableTypes = true,
                                        compositeLiteralFields = true,
                                        compositeLiteralTypes = true,
                                        constantValues = true,
                                        functionTypeParameters = true,
                                        parameterNames = true,
                                        rangeVariableTypes = true,
                                    },
                                    analyses = {
                                        fieldalignment = true,
                                        nilness = true,
                                        unusedparams = true,
                                        unusedwrite = true,
                                        useany = true,
                                    },
                                    usePlaceholders = true,
                                    completeUnimported = true,
                                    staticcheck = true,
                                    directoryFilters = {
                                        "-.git",
                                        "-.vscode",
                                        "-.idea",
                                        "-.vscode-test",
                                        "-node_modules",
                                    },
                                    semanticTokens = true,
                                },
                            },
                        })
                    end,
                },
            })

            vim.diagnostic.config({
                virtual_text = false,
                float = {
                    -- UI.
                    header = nil,
                    border = "rounded",
                    focusable = true,
                },
            })

            local signs = {
                Error = "",
                Warn = "",
                Hint = "",
                Info = "",
            }

            for type, icon in pairs(signs) do
                local hl = "DiagnosticSign" .. type
                vim.fn.sign_define(
                    hl,
                    { text = icon, texthl = hl, numhl = nil }
                )
            end
        end,
    },
}

function helpers.setupLspRoundedBorders()
    vim.lsp.handlers["textDocument/signatureHelp"] =
        vim.lsp.with(vim.lsp.handlers.signature_help, {
            border = "rounded",
            title = "signature",
        })

    vim.lsp.handlers["textDocument/hover"] =
        vim.lsp.with(vim.lsp.handlers.hover, {
            -- Use a sharp border with `FloatBorder` highlights
            border = "rounded",
            -- add the title in hover float window
            title = "hover",
        })
end

--- @param client vim.lsp.Client
--- @param bufNr number
function helpers.enableLspFeatures(client, bufNr)
    if client.supports_method("textDocument/completion") then
        vim.bo[bufNr].omnifunc = "v:lua.vim.lsp.omnifunc"
    end
    if client.supports_method("textDocument/definition") then
        vim.bo[bufNr].tagfunc = "v:lua.vim.lsp.tagfunc"
    end

    if client.server_capabilities.inlayHintProvider then
        vim.lsp.inlay_hint.enable(true, {
            bufnr = bufNr,
        })
    end
end

--- @param client vim.lsp.Client
--- @param bufNr number
function helpers.onLspAttach(client, bufNr)
    helpers.enableLspFeatures(client, bufNr)

    ---@param when string|string[]
    ---@param keyCombination string
    ---@param action function|string
    ---@param desc string|nil
    local lspKeymap = function(when, keyCombination, action, desc)
        local opts = { buffer = bufNr }
        if desc then
            opts.desc = desc
        end

        vim.keymap.set(when, keyCombination, action, opts)
    end

    lspKeymap("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")

    lspKeymap(
        "n",
        "go",
        "<cmd>Telescope lsp_type_definitions<CR>",
        "Go to object type definition"
    )

    lspKeymap(
        "n",
        "gi",
        "<cmd>Telescope lsp_implementations<CR>",
        "Go to implementation"
    )

    lspKeymap(
        "n",
        "gd",
        "<cmd>Telescope lsp_definitions<CR>",
        "Go to definition"
    )

    -- Not using LSPSage as it can't be resumed and reused
    lspKeymap(
        "n",
        "gr",
        "<cmd>Telescope lsp_references<CR>",
        "List references using Telescope"
    )

    lspKeymap(
        "n",
        "<leader>rw",
        "<cmd>Telescope lsp_workspace_symbols<CR>",
        "Search for symbol in workspace"
    )

    lspKeymap(
        "n",
        "<leader>rd",
        "<cmd>Telescope lsp_document_symbols<CR>",
        "Search for symbol in document"
    )

    -- Enabled this because the floating input accepts all motions, LSP Saga doesn't
    lspKeymap(
        "n",
        "<leader>rn",
        vim.lsp.buf.rename,
        "Rename symbol with native NVim lsp"
    )

    lspKeymap(
        "i",
        "<C-h>",
        vim.lsp.buf.signature_help,
        "Show help for function signature"
    )

    lspKeymap(
        { "n", "v" },
        "<leader>ca",
        vim.lsp.buf.code_action,
        "Show code actions"
    )
end

return M
