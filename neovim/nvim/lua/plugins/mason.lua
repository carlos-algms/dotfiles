return {
    "williamboman/mason.nvim",

    dependencies = {
        { "williamboman/mason-lspconfig.nvim" },
        { "neovim/nvim-lspconfig" },
        { "hrsh7th/nvim-cmp" }, -- adding it here to wait for it to config
        { "hrsh7th/cmp-nvim-lsp" },
        { "WhoIsSethDaniel/mason-tool-installer.nvim" },
        { "nvim-telescope/telescope.nvim" }, -- listing it here to import builtin safely

        -- Disabled to keep using typescript-tools.nvim
        -- { "yioneko/nvim-vtsls" },

        {
            "folke/lazydev.nvim",
            ft = "lua", -- only load on lua files
            opts = {
                library = {
                    -- Library items can be absolute paths
                    -- "~/projects/my-awesome-lib",
                    -- Or relative, which means they will be resolved as a plugin
                    -- "LazyVim",
                    -- When relative, you can also provide a path to the library in the plugin dir
                    -- "luvit-meta/library", -- see below
                },
            },
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

        vim.lsp.handlers["textDocument/signatureHelp"] =
            vim.lsp.with(vim.lsp.handlers.signature_help, {
                border = "single",
                title = "signature",
            })

        vim.lsp.handlers["textDocument/hover"] =
            vim.lsp.with(vim.lsp.handlers.hover, {
                -- Use a sharp border with `FloatBorder` highlights
                border = "single",
                -- add the title in hover float window
                title = "hover",
            })

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

                local bufNr = ev.buf
                if client.supports_method("textDocument/completion") then
                    vim.bo[bufNr].omnifunc = "v:lua.vim.lsp.omnifunc"
                end
                if client.supports_method("textDocument/definition") then
                    vim.bo[bufNr].tagfunc = "v:lua.vim.lsp.tagfunc"
                end

                local noKeymapLspClients = {
                    "null-ls",
                    "GitHub Copilot",
                }

                for _, clientName in ipairs(noKeymapLspClients) do
                    if client.name == clientName then
                        return
                    end
                end

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

                -- enabled again, instead of lspsaga, as I can resume it after closing
                lspKeymap(
                    "n",
                    "gr",
                    telescopeBuiltin.lsp_references,
                    "List [r]eferences using Telescope"
                )

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

                -- Enabled this because the floating input accepts all motions, LSP Saga doesn't
                lspKeymap(
                    "n",
                    "<leader>rn",
                    vim.lsp.buf.rename,
                    "[R]ename symbol with native NVim lsp"
                )

                lspKeymap(
                    "i",
                    "<C-h>",
                    vim.lsp.buf.signature_help,
                    "Show [h]elp for function signature"
                )

                lspKeymap(
                    { "n", "v" },
                    "<leader>ca",
                    vim.lsp.buf.code_action,
                    "Show [c]ode [a]ctions"
                )

                -- Disabled to use Conform
                -- lspKeymap("n", "<leader>bf", function()
                --     vim.lsp.buf.format({ async = true })
                -- end, "[B]uffer [F]ormat")
            end,
        })

        require("mason").setup()

        local ensureToolsInstalled = {
            "shfmt",
            "stylua",
            "black",
        }

        local ensureLspInstalled = {
            "bashls",
            "lua_ls",
        }

        if vim.g.has_node then
            table.insert(ensureToolsInstalled, "prettier")
            ensureLspInstalled =
                table.shallowMerge(ensureLspInstalled, { "jsonls" })
        end

        if not vim.g.is_ssh then
            if vim.g.has_node then
                table.insert(ensureToolsInstalled, "js-debug-adapter")
                ensureLspInstalled = table.shallowMerge(ensureLspInstalled, {
                    -- not installing tsserver because of ts-tools plugin
                    -- "tsserver",
                    -- "ts_ls",
                    "html",
                    "cssls",
                    "intelephense",
                })
            end
        end

        require("mason-tool-installer").setup({
            -- a list of all tools you want to ensure are installed upon
            -- start
            ensure_installed = ensureToolsInstalled,
        })

        local masonLspConfig = require("mason-lspconfig")

        local lspConfig = require("lspconfig")

        -- require("lspconfig.configs").vtsls = require("vtsls").lspconfig

        local all_lsp_capabilities = vim.tbl_deep_extend(
            "force",
            vim.lsp.protocol.make_client_capabilities(),
            require("cmp_nvim_lsp").default_capabilities()
        )

        masonLspConfig.setup({
            ensure_installed = ensureLspInstalled,
            handlers = {
                function(server_name)
                    -- just make sure they are disabled, as I'm using typescript-tools.nvim
                    if server_name == "ts_ls" or server_name == "tsserver" then
                        return false
                    end

                    lspConfig[server_name].setup({
                        capabilities = all_lsp_capabilities,
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

                -- Disabled to use typescript-tools.nvim
                -- ts_ls = function()
                --     -- tsserver was renamed to ts_ls
                --     -- https://github.com/neovim/nvim-lspconfig/pull/3232#issuecomment-2331025714
                --     -- I'm not using the ts_ls, as I'm using typescript-tools.nvim
                --     return false
                -- end,
                --
                -- tsserver = function()
                --     local function organize_imports()
                --         local params = {
                --             command = "_typescript.organizeImports",
                --             arguments = { vim.api.nvim_buf_get_name(0) },
                --         }
                --         vim.lsp.buf.execute_command(params)
                --     end

                --     lspconfig.tsserver.setup({
                --         capabilities = lsp_capabilities,
                --         init_options = {
                --             preferences = {
                --                 disableSuggestions = false,
                --             },
                --         },
                --         commands = {
                --             OrganizeImports = {
                --                 organize_imports,
                --                 description = "Organize Imports",
                --             },
                --         },
                --     })
                --     return false
                -- end,
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
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = nil })
        end
    end,
}
