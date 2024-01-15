return {
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            { "hrsh7th/cmp-nvim-lsp" },
            -- TODO: import from VSCode and how can I write my own snippets?
            { "rafamadriz/friendly-snippets" },
            {
                "L3MON4D3/LuaSnip",
                -- follow latest release.
                version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
                -- install jsregexp (optional!:).
                build = "make install_jsregexp",
            },
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            local cmp_select = { behavior = cmp.SelectBehavior.Select }

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                sources = cmp.config.sources({
                    { name = "path" },
                    { name = "nvim_lsp", keyword_length = 1 },
                    { name = "nvim_lsp_signature_help" },
                    { name = "luasnip" },
                    { name = "nvim_lua" },
                }, {
                    { name = "buffer" },
                }),
                -- TODO how to format? Or do I even need to format here?
                --    formatting = lsp_zero.cmp_format(),
                mapping = cmp.mapping.preset.insert({
                    ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
                    ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
                    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                    ["<Cr>"] = cmp.mapping.confirm({ select = true }),
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
                    -- IF I enable TAB, copilot seems to stop working
                    -- ["<Tab>"] = cmp.mapping(function(fallback)
                    --     if cmp.visible() then
                    --         cmp.select_next_item()
                    --     elseif has_words_before() then
                    --         cmp.complete()
                    --     else
                    --         fallback()
                    --     end
                    -- end, { "i", "s" }),
                    -- ["<S-Tab>"] = cmp.mapping(function(fallback)
                    --     if cmp.visible() then
                    --         cmp.select_prev_item()
                    --     else
                    --         fallback()
                    --     end
                    -- end, { "i", "s" }),
                }),
            })
        end,
    },
}
