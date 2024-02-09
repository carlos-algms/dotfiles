return {
    "williamboman/mason.nvim",

    dependencies = {
        { "williamboman/mason-lspconfig.nvim" },
        { "neovim/nvim-lspconfig" },
        { "hrsh7th/nvim-cmp" }, -- adding it here to wait for it to config
        { "hrsh7th/cmp-nvim-lsp" },
        { "WhoIsSethDaniel/mason-tool-installer.nvim" },
        { "nvim-telescope/telescope.nvim" }, -- listing it here to import builtin safely

        {
            -- apparently it should be installed before lspconfig
            "folke/neodev.nvim",
            -- TODO: enable it only for the nvim folder
            -- enabled = false,
            -- add lazy here as wasn't initializing all the time
            lazy = false,
            config = function()
                require("neodev").setup({})
            end,
        },
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
            },
        })
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

        -- vim.lsp.handlers["textDocument/signatureHelp"] =
        --     vim.lsp.with(vim.lsp.handlers.signature_help, {
        --         border = "single",
        --         title = "signature",
        --     })

        -- vim.lsp.handlers["textDocument/hover"] =
        --     vim.lsp.with(vim.lsp.handlers.hover, {
        --         -- Use a sharp border with `FloatBorder` highlights
        --         border = "single",
        --         -- add the title in hover float window
        --         title = "hover",
        --     })

        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            desc = "LSP actions",
            callback = function(ev)
                -- Enable completion triggered by <c-x><c-o>
                vim.bo[ev.buf].omnifunc = "vim.lsp.omnifunc" --"v:lua.vim.lsp.omnifunc"

                local lspKeymap = function(when, keyCombination, action, desc)
                    local opts = { buffer = ev.buf }
                    if desc then
                        opts.desc = desc
                    end

                    vim.keymap.set(when, keyCombination, action, opts)
                end

                lspKeymap(
                    "n",
                    "gD",
                    vim.lsp.buf.declaration,
                    "[G]o to [D]eclaration"
                )

                local telescopeBuiltin = require("telescope.builtin")

                lspKeymap(
                    "n",
                    "go",
                    telescopeBuiltin.lsp_type_definitions,
                    "[G]o to [o]bject type definition"
                )

                lspKeymap(
                    "n",
                    "gi",
                    telescopeBuiltin.lsp_implementations,
                    "[G]o to [i]mplementation"
                )

                lspKeymap(
                    "n",
                    "gd",
                    -- went with Telescope, as it is better when there are more than 1 result
                    -- vim.lsp.buf.definition,
                    telescopeBuiltin.lsp_definitions,
                    "[G]o to [d]efinition"
                )

                -- Implemented on telescope, as it has a better UI
                -- lspKeymap("n", "gr", vim.lsp.buf.references, opts)

                -- disabled to use LSP Saga
                -- lspKeymap(
                --     "n",
                --     "gr",
                --     telescopeBuiltin.lsp_references,
                --     { desc = "List [r]eferences using Telescope" }
                -- )

                lspKeymap("n", "K", vim.lsp.buf.hover, "Show Hover information")

                lspKeymap(
                    "n",
                    "<leader>rw",
                    telescopeBuiltin.lsp_workspace_symbols,
                    "Search for symbol in [w]orkspace"
                )

                lspKeymap(
                    "n",
                    "<leader>rd",
                    telescopeBuiltin.lsp_document_symbols,
                    "Search for symbol in [d]ocument"
                )

                -- lspKeymap(
                --     "n",
                --     "<leader>rn",
                --     vim.lsp.buf.rename,
                --     "[R]ename symbol"
                -- )

                lspKeymap(
                    "i",
                    "<C-h>",
                    vim.lsp.buf.signature_help,
                    "Show [h]elp for function signature"
                )

                lspKeymap(
                    { "n", "v" },
                    "<space>ca",
                    vim.lsp.buf.code_action,
                    "Show [c]ode [a]ctions"
                )

                lspKeymap("n", "<space>bf", function()
                    vim.lsp.buf.format({ async = true })
                end, "[B]uffer [F]ormat")
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
                    -- Disabled to use typescript-tools.nvim
                    -- lspconfig.tsserver.setup({
                    --     capabilities = lsp_capabilities,
                    --     init_options = {
                    --         preferences = {
                    --             disableSuggestions = false,
                    --         },
                    --     },
                    --     commands = {
                    --         OrganizeImports = {
                    --             organize_imports,
                    --             description = "Organize Imports",
                    --         },
                    --     },
                    -- })
                end,
            },
        })

        vim.diagnostic.config({
            virtual_text = false,
            float = {
                -- UI.
                header = false,
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
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = nil })
            vim.cmd("hi! " .. hl .. " guibg=#313335 guifg=#bac4cf")
        end
    end,
}
