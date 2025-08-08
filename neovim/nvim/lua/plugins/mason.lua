local M = {
    {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
            library = {
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },

    {
        "mason-org/mason.nvim",

        dependencies = {
            { "mason-org/mason-lspconfig.nvim" },
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
                    alloy = "hcl", -- Grafana Alloy language, not perfect, better than no highlighting
                    mdx = "markdown",
                    avanterules = "markdown",
                },
                filename = {
                    [".zshrc"] = "sh",
                    [".zprofile"] = "sh",
                    [".zshenv"] = "sh",
                    ["composer.lock"] = "json",
                    ["phpstan.neon"] = "yaml",
                    [".env"] = "confini",
                },
                pattern = {
                    ["%.vscode/.*%.json"] = "jsonc",
                    [".*%.gitconfig"] = "gitconfig",
                    ["%.env%..*"] = "confini",
                    -- it doesn't seem the gh-lsp requires it
                    -- [".*/%.github[%w/]+workflows[%w/]+.*%.ya?ml"] = "yaml.github",
                },
            })

            -- vim.treesitter.language.register("markdown", "jinja")
            vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
                pattern = { "*.avanterules" },
                callback = function()
                    vim.cmd("setlocal syntax=markdown")
                end,
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

            require("mason").setup({
                -- In case I want to test a new registry I need to clone my fork of mason-registry
                -- registries = {
                --     "file:~/projects/mason-registry",
                -- },
            })

            local tables = require("helpers.tables")

            local ensureToolsInstalled = {
                "stylua",
                -- "black",
            }

            local ensureLspInstalled = {
                "lua_ls",
            }

            if vim.g.has_node then
                -- These need npm to be installed, not to run, most have a binary
                tables.deep_extend(ensureToolsInstalled, {
                    "shfmt",
                    "prettier",
                })

                tables.deep_extend(ensureLspInstalled, {
                    "bashls",
                    "dockerls",
                    "docker_compose_language_service",
                    "jsonls",
                    "yamlls",
                })
            end

            if not vim.g.is_ssh then
                if vim.g.has_node then
                    tables.deep_extend(
                        ensureToolsInstalled,
                        { "js-debug-adapter" }
                    )

                    tables.deep_extend(ensureLspInstalled, {
                        "vtsls",
                        -- "phpactor", -- requires PHP in PATH, and doesn't seem as good as intelephense
                        "intelephense",
                        "emmet_language_server",
                        "html",
                        "cssls",
                        "eslint",
                        "tailwindcss",
                    })
                end
            end

            if vim.fn.executable("go") == 1 then
                tables.deep_extend(ensureLspInstalled, { "gopls" })
                tables.deep_extend(ensureToolsInstalled, {
                    "goimports",
                    -- "goimports-reviser", -- disabled as it requires go.mod to exist
                })
            end

            require("mason-tool-installer").setup({
                ensure_installed = ensureToolsInstalled,
            })

            require("lspconfig.configs").vtsls = require("vtsls").lspconfig

            local all_lsp_capabilities =
                require("cmp_nvim_lsp").default_capabilities(
                    vim.lsp.protocol.make_client_capabilities()
                )

            local disabledLspServers = {
                "ts_ls",
                "tsserver",
            }

            vim.lsp.config("*", {
                capabilities = all_lsp_capabilities,
                on_attach = function(client, bufNr)
                    require("helpers.lsp_helpers").onLspAttach(client, bufNr)
                end,
            })

            require("mason-lspconfig").setup({
                ensure_installed = ensureLspInstalled,
                automatic_enable = {
                    exclude = disabledLspServers,
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

return M
