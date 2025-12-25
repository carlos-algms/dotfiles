return {
    {

        "saghen/blink.cmp", -- https://cmp.saghen.dev/installation
        version = "1.*", -- use a release tag to download pre-built binaries

        event = { "InsertEnter", "CmdlineEnter" },

        dependencies = {
            { "L3MON4D3/LuaSnip" },

            {
                "kristijanhusak/vim-dadbod-completion",
                ft = { "sql", "mysql", "plsql" },
            },

            { "moyiz/blink-emoji.nvim" },
        },

        ---@module 'blink.cmp'
        ---@param maybeOpts blink.cmp.Config
        opts = function(_, maybeOpts)
            ---@type blink.cmp.Config
            local localOpts = {
                snippets = {
                    preset = "luasnip",
                },

                sources = {
                    default = { "lsp", "emoji", "path", "snippets", "buffer" },

                    per_filetype = {
                        sql = { inherit_defaults = true, "dadbod" },
                        lua = { inherit_defaults = true, "lazydev" },
                    },

                    providers = {
                        dadbod = {
                            name = "Dadbod",
                            module = "vim_dadbod_completion.blink",
                        },

                        lazydev = {
                            name = "LazyDev",
                            module = "lazydev.integrations.blink",
                            score_offset = 100,
                        },

                        path = {
                            score_offset = 25,
                            -- When typing a path, I would get snippets and text in the
                            -- suggestions, I want those to show only if there are no path
                            -- suggestions
                            fallbacks = { "snippets", "buffer" },
                            -- min_keyword_length = 2,
                            opts = {
                                trailing_slash = false,
                                label_trailing_slash = true,
                                show_hidden_files_by_default = true,
                            },
                        },

                        --- this is the words in the current buffer
                        buffer = {
                            max_items = 4,
                            min_keyword_length = 2,
                            score_offset = 15, -- the higher the number, the higher the priority
                        },

                        emoji = {
                            module = "blink-emoji",
                            name = "Emoji",
                            score_offset = 15,
                            opts = {
                                insert = true, -- Insert emoji (default) or complete its name
                                ---@type string|table|fun():table
                                trigger = function()
                                    return { ":" }
                                end,
                            },
                        },
                    },
                },

                -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
                -- 'super-tab' for mappings similar to vscode (tab to accept)
                -- 'enter' for enter to accept
                -- 'none' for no mappings
                --
                -- All presets have the following mappings:
                -- C-space: Open menu or open docs if already open
                -- C-n/C-p or Up/Down: Select next/previous item
                -- C-e: Hide menu
                -- C-k: Toggle signature help (if signature.enabled = true)
                --
                -- See :h blink-cmp-config-keymap for defining your own keymap
                keymap = { preset = "super-tab" },

                cmdline = {
                    keymap = { preset = "inherit" },
                    completion = { menu = { auto_show = true } },
                },

                appearance = {
                    -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                    -- Adjusts spacing to ensure icons are aligned
                    nerd_font_variant = "mono",
                },

                completion = {
                    -- 'prefix' will fuzzy match on the text before the cursor
                    -- 'full' will fuzzy match on the text before _and_ after the cursor
                    -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
                    keyword = { range = "prefix" },

                    trigger = {
                        show_on_backspace = true,
                        show_on_backspace_in_keyword = true,
                    },

                    ghost_text = { enabled = false }, -- to not confuse with copilot ghost text

                    list = {
                        selection = { preselect = true, auto_insert = false },
                    },

                    menu = { border = "rounded" },
                    documentation = {
                        auto_show = true,
                        window = { border = "rounded" },
                    },
                },

                signature = {
                    enabled = true,
                    window = { border = "rounded" },
                },

                -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
                -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
                -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
                --
                -- See the fuzzy documentation for more information
                fuzzy = { implementation = "prefer_rust_with_warning" },
            }

            local mergedOpts =
                vim.tbl_deep_extend("force", {}, maybeOpts or {}, localOpts)

            return mergedOpts
        end,

        opts_extend = { "sources.default" },
    },
}
