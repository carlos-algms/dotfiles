return {
    {
        -- TODO: it doesn't seem to be working with autocomplete
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

            -- Disabled to keep using typescript-tools.nvim
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

            -- vim.keymap.set(
            --     "n",
            --     "[d",
            --     vim.diagnostic.goto_prev,
            --     { desc = "Go to previous problem" }
            -- )

            -- vim.keymap.set(
            --     "n",
            --     "]d",
            --     vim.diagnostic.goto_next,
            --     { desc = "Go to next problem" }
            -- )

            -- disabled to use LSP Saga
            -- vim.keymap.set("n", "]e", function()
            --     vim.diagnostic.goto_next({
            --         severity = vim.diagnostic.severity.ERROR,
            --     })
            -- end, { desc = "Go to next Erro" })

            -- vim.keymap.set("n", "[e", function()
            --     vim.diagnostic.goto_prev({
            --         severity = vim.diagnostic.severity.ERROR,
            --     })
            -- end, { desc = "Go to previous Error" })

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

            local bufferBoundCache = {}

            -- TODO: I might be able to extract this and add to the `on_attach` method of the LSP servers config, so I don't need to check for individual servers
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup(
                    "UserLspConfig",
                    { clear = true }
                ),
                desc = "LSP actions",
                callback = function(ev)
                    -- https://neovim.io/doc/user/lsp.html#lsp-events
                    local client = vim.lsp.get_client_by_id(ev.data.client_id)
                    if client == nil then
                        return
                    end

                    local noKeymapLspClients = {
                        "null-ls",
                        "GitHub Copilot",
                        "copilot",
                        "eslint",
                    }

                    for _, clientName in ipairs(noKeymapLspClients) do
                        if client.name == clientName then
                            return
                        end
                    end

                    local bufNr = ev.buf

                    if bufferBoundCache[bufNr] then
                        return
                    end

                    bufferBoundCache[bufNr] = true

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

                    local lspKeymap = function(
                        when,
                        keyCombination,
                        action,
                        desc
                    )
                        local opts = { buffer = bufNr }
                        if desc then
                            opts.desc = desc
                        end

                        vim.keymap.set(when, keyCombination, action, opts)
                    end

                    lspKeymap(
                        "n",
                        "gD",
                        vim.lsp.buf.declaration,
                        "Go to Declaration"
                    )

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
                        -- went with Telescope, as it is better when there are more than 1 result
                        -- vim.lsp.buf.definition,
                        "<cmd>Telescope lsp_definitions<CR>",
                        "Go to definition"
                    )

                    -- enabled again, instead of lspsaga, as I can resume it after closing
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

                    -- Disabled to use Conform
                    -- lspKeymap("n", "<leader>bf", function()
                    --     vim.lsp.buf.format({ async = true })
                    -- end, "[B]uffer [F]ormat")
                end,
            })

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
                        -- not installing tsserver because of ts-tools plugin
                        -- "tsserver",
                        -- "ts_ls",
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
                -- a list of all tools you want to ensure are installed upon start
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
                                local vtslsCommands = require("vtsls").commands

                                vim.keymap.set(
                                    { "n", "v" },
                                    "<leader>io",
                                    function()
                                        vtslsCommands.organize_imports(bufNr)
                                    end,
                                    {
                                        desc = "Imports Organize",
                                        silent = true,
                                        buffer = bufNr,
                                    }
                                )

                                vim.keymap.set(
                                    { "n", "v" },
                                    "<leader>is",
                                    function()
                                        vtslsCommands.sort_imports(bufNr)
                                    end,
                                    {
                                        desc = "Imports Sort",
                                        silent = true,
                                        buffer = bufNr,
                                    }
                                )

                                vim.keymap.set(
                                    { "n", "v" },
                                    "<leader>ir",
                                    function()
                                        vtslsCommands.remove_unused_imports(
                                            bufNr
                                        )
                                    end,
                                    {
                                        desc = "Imports remove unused",
                                        silent = true,
                                        buffer = bufNr,
                                    }
                                )

                                vim.keymap.set(
                                    { "n", "v" },
                                    "<leader>ia",
                                    function()
                                        vtslsCommands.add_missing_imports(bufNr)
                                    end,
                                    {
                                        desc = "Imports Add All missing",
                                        silent = true,
                                        buffer = bufNr,
                                    }
                                )

                                vim.keymap.set(
                                    { "n", "v" },
                                    "<leader>rf",
                                    function()
                                        vtslsCommands.rename_file(bufNr)
                                    end,
                                    {
                                        desc = "Rename File",
                                        silent = true,
                                        buffer = bufNr,
                                    }
                                )

                                vim.keymap.set(
                                    { "n", "v" },
                                    "<leader>ct",
                                    function()
                                        vtslsCommands.select_ts_version(bufNr)
                                    end,
                                    {
                                        desc = "Select Typescript Version",
                                        silent = true,
                                        buffer = bufNr,
                                    }
                                )

                                vim.keymap.set({ "n", "v" }, "gD", function()
                                    vtslsCommands.goto_source_definition(nil)
                                end, {
                                    desc = "Go to source definition",
                                    silent = true,
                                    buffer = bufNr,
                                })
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
                            settings = {
                                json = {
                                    schemas = require("schemastore").json.schemas(),
                                    validate = { enable = true },
                                },
                            },
                        })
                    end,

                    yamlls = function()
                        lspConfig.yamlls.setup({
                            capabilities = all_lsp_capabilities,
                            settings = {
                                yaml = {
                                    schemaStore = {
                                        enable = false,
                                        url = "",
                                    },
                                    schemas = require("schemastore").yaml.schemas(),
                                },
                            },
                        })
                    end,

                    lua_ls = function()
                        lspConfig.lua_ls.setup({
                            capabilities = all_lsp_capabilities,
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
                        -- return false
                        lspConfig.intelephense.setup({
                            capabilities = all_lsp_capabilities,
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
