return {
    {
        "L3MON4D3/LuaSnip",
        version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)

        event = "InsertEnter",

        -- install jsregexp (optional!:).
        build = "make install_jsregexp",

        dependencies = {},

        config = function()
            local ls = require("luasnip")

            -- borrowed from
            -- https://github.com/garcia5/dotfiles/blob/92621b3fc552744253f90c285caa5ba0790c6bb8/files/nvim/lua/ag/plugins/luasnip.lua
            ls.setup({
                -- keep_roots = false,
                -- link_roots = false,
                -- link_children = false,
                -- Update snippet text in _real time_
                updateevents = { "TextChanged", "TextChangedI" },
                enable_autosnippets = true,
                delete_check_events = { "InsertLeave" },
                -- Show virtual text hints for node types
                -- ext_opts = {
                --     [types.insertNode] = {
                --         active = {
                --             virt_text = { { "●", "Operator" } },
                --         },
                --     },
                --     [types.choiceNode] = {
                --         active = {
                --             virt_text = { { "●", "Constant" } },
                --         },
                --     },
                -- },
            })

            -- this one is for the friendly-snippets, but I'm not using it.
            -- require("luasnip.loaders.from_vscode").lazy_load()

            -- https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#vs-code
            require("luasnip.loaders.from_vscode").lazy_load({
                paths = "./lua/snippets",
            })

            require("luasnip.loaders.from_lua").lazy_load({
                paths = "./lua/snippets",
            })

            -- js_and_ts.lua snippets shared across JS/TS filetypes
            ls.filetype_extend("typescript", { "js_and_ts" })
            ls.filetype_extend("typescriptreact", { "js_and_ts" })
            ls.filetype_extend("javascript", { "js_and_ts" })
            ls.filetype_extend("javascriptreact", { "js_and_ts" })

            -- AgenticNvim buffers use markdown snippets
            ls.filetype_extend("AgenticInput", { "markdown" })
        end,
    },
}
