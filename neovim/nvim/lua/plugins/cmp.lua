return {
    {
        "hrsh7th/nvim-cmp",
        event = { "VeryLazy" },
        dependencies = {
            { "hrsh7th/cmp-nvim-lsp" },
            { "hrsh7th/cmp-buffer" },
            { "hrsh7th/cmp-path" },
            { "hrsh7th/cmp-cmdline" },
            { "hrsh7th/cmp-nvim-lua" },
            { "saadparwaiz1/cmp_luasnip" },
            -- TODO: import from VSCode and how can I write my own snippets?
            -- https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#vs-code
            {
                "L3MON4D3/LuaSnip",
                -- follow latest release.
                version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
                -- install jsregexp (optional!:).
                build = "make install_jsregexp",
                dependencies = {
                    { "rafamadriz/friendly-snippets" },
                },
            },
            {
                "onsails/lspkind.nvim",
            },
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            local lspkind = require("lspkind")
            local cmp_select = { behavior = cmp.SelectBehavior.Select }

            -- https://github.com/L3MON4D3/LuaSnip#add-snippets
            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                -- completion = {
                --     completeopt = "menu,menuone,noinsert",
                -- },
                sources = cmp.config.sources({
                    { name = "nvim_lsp_signature_help" },
                    { name = "nvim_lsp" },
                    {
                        name = "luasnip",
                        keyword_length = 2,
                        max_item_count = 5,
                    },
                    {
                        name = "nvim_lua",
                        keyword_length = 2,
                        max_item_count = 5,
                    },
                    { name = "path", keyword_length = 2, max_item_count = 5 },
                }, {
                    { name = "buffer", keyword_length = 2, max_item_count = 5 },
                }),

                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },

                formatting = {
                    format = lspkind.cmp_format({
                        mode = "symbol_text",
                        show_labelDetails = true,
                        preset = "default",
                    }),
                },

                mapping = cmp.mapping.preset.insert({
                    ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
                    ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
                    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                    ["<Cr>"] = cmp.mapping.confirm({ select = true }),
                    -- https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings#safely-select-entries-with-cr
                    -- ["<CR>"] = cmp.mapping({
                    --     i = function(fallback)
                    --         if cmp.visible() then
                    --             cmp.confirm({
                    --                 behavior = cmp.ConfirmBehavior.Replace,
                    --                 select = true,
                    --             })
                    --         else
                    --             fallback()
                    --         end
                    --     end,
                    --     s = cmp.mapping.confirm({ select = true }),
                    --     c = cmp.mapping.confirm({
                    --         behavior = cmp.ConfirmBehavior.Replace,
                    --         select = true,
                    --     }),
                    -- }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-b>"] = cmp.mapping(
                        cmp.mapping.scroll_docs(-4),
                        { "i", "c" }
                    ),
                    ["<C-f>"] = cmp.mapping(
                        cmp.mapping.scroll_docs(4),
                        { "i", "c" }
                    ),
                    ["<PageUp>"] = cmp.mapping(
                        cmp.mapping.scroll_docs(-4),
                        { "i", "c" }
                    ),
                    ["<PageDown>"] = cmp.mapping(
                        cmp.mapping.scroll_docs(4),
                        { "i", "c" }
                    ),

                    -- I want to use <Tab> only for jumps on the snippets sections,
                    -- otherwise fallback to Copilot
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        local copilot_keys = vim.fn["copilot#Accept"]()

                        if
                            copilot_keys ~= ""
                            and type(copilot_keys) == "string"
                        then
                            vim.api.nvim_feedkeys(copilot_keys, "i", true)
                        elseif luasnip.locally_jumpable(1) then
                            luasnip.jump(1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),

                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if luasnip.locally_jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
            })

            cmp.setup.cmdline({ "/", "?" }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = "buffer" },
                },
            })

            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path" },
                }, {
                    { name = "cmdline" },
                }),
            })
        end,
    },
}
