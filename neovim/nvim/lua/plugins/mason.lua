return {
    "williamboman/mason.nvim",

    dependencies = {
        { "williamboman/mason-lspconfig.nvim" },
        { "neovim/nvim-lspconfig" },
        { "hrsh7th/cmp-nvim-lsp" },
        { "WhoIsSethDaniel/mason-tool-installer.nvim" },
    },

    config = function()
        --
        -- https://github.com/neovim/nvim-lspconfig#suggested-configuration
        -- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/you-might-not-need-lsp-zero.md

        -- note: diagnostics are not exclusive to lsp servers
        -- so these can be global keybindings
        vim.keymap.set("n", "gl", vim.diagnostic.open_float)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next)

        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            desc = "LSP actions",
            callback = function(ev)
                -- Enable completion triggered by <c-x><c-o>
                vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
                local opts = { buffer = ev.buf }

                vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
                vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
                vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
                -- Implemented on telescope, as it has a better UI
                -- vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
                vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
                vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
                vim.keymap.set("n", "<space>f", function()
                    vim.lsp.buf.format({ async = true })
                end, opts)
            end,
        })

        require("mason").setup()

        require("mason-tool-installer").setup({

            -- a list of all tools you want to ensure are installed upon
            -- start
            ensure_installed = {
                "prettier",
                "shfmt",
                "stylua",
                "js-debug-adapter",
                "black",
            },
        })

        local masonLspconfig = require("mason-lspconfig")

        local lspconfig = require("lspconfig")
        local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()

        local function organize_imports()
            local params = {
                command = "_typescript.organizeImports",
                arguments = { vim.api.nvim_buf_get_name(0) },
            }
            vim.lsp.buf.execute_command(params)
        end

        masonLspconfig.setup({
            ensure_installed = {
                "tsserver",
                "bashls",
                "html",
                "cssls",
                "lua_ls",
                "intelephense",
            },
            handlers = {
                function(server_name)
                    lspconfig[server_name].setup({
                        capabilities = lsp_capabilities,
                    })
                end,

                lua_ls = function()
                    lspconfig.lua_ls.setup({
                        capabilities = lsp_capabilities,
                        settings = {
                            Lua = {
                                diagnostics = {
                                    globals = { "vim", "get_args" },
                                },
                            },
                        },
                    })
                end,

                tsserver = function()
                    lspconfig.tsserver.setup({
                        capabilities = lsp_capabilities,
                        init_options = {
                            preferences = {
                                disableSuggestions = false,
                            },
                        },
                        commands = {
                            OrganizeImports = {
                                organize_imports,
                                description = "Organize Imports",
                            },
                        },
                    })
                end,
            },
        })

        vim.diagnostic.config({
            virtual_text = true,
        })
    end,
}
