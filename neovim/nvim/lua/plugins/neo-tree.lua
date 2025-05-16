-- vim.g.loaded_netrw = 1
-- vim.g.loaded_netrwPlugin = 1

return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        enabled = true,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            "MunifTanjim/nui.nvim",
        },
        -- init = function()
        --     if vim.fn.argc(-1) == 1 then
        --         local stat = vim.loop.fs_stat(vim.fn.argv(0))
        --         if stat and stat.type == "directory" then
        --             require("neo-tree")
        --         end
        --     end
        -- end,
        cmd = { "Neotree" },

        keys = {
            {
                "<C-S-n>",
                "<cmd>Neotree filesystem reveal left<CR>",
                mode = { "n", "v", "x" },
                desc = "Reveal current file in NeoTree ",
                silent = true,
            },
        },

        opts = {
            popup_border_style = "rounded",
            sources = {
                "filesystem",
                "buffers",
                "git_status",
                "document_symbols",
            },
            enable_git_status = true,
            enable_diagnostics = false,
            sort_case_insensitive = true,
            default_component_config = {
                group_empty_dirs = true,
            },

            filesystem = {
                filtered_items = {
                    visible = false, -- when true, they will just be displayed differently than normal items
                    hide_dotfiles = false,
                    hide_gitignored = true,
                },
                -- it's difficult to move files arround when multiple dirs are grouped
                group_empty_dirs = false,
                window = {
                    mappings = {
                        ["F"] = "fuzzy_finder",
                    },
                },
            },

            event_handlers = {
                -- {
                --     event = "file_opened",
                --     handler = function(file_path)
                --         -- auto close
                --         vim.cmd("Neotree close")
                --         -- OR
                --         -- require("neo-tree.command").execute({ action = "close" })
                --     end,
                -- },
            },

            window = {
                position = "left",
                width = 40,
                mapping_options = {
                    noremap = true,
                    nowait = true,
                },
                -- default mappings for all sources
                mappings = {
                    ["a"] = {
                        "add",
                        -- this command supports BASH style brace expansion ("x{a,b,c}" -> xa,xb,xc). see `:h neo-tree-file-actions` for details
                        -- some commands may take optional config options, see `:h neo-tree-mappings` for details
                        config = {
                            show_path = "relative", -- "none", "relative", "absolute"
                        },
                    },
                    ["A"] = {
                        "add_directory",
                        config = {
                            show_path = "relative",
                        },
                    },
                    ["m"] = {
                        "move",
                        config = {
                            show_path = "relative",
                        },
                    },
                    ["/"] = false, -- "fuzzy_finder",
                },
            },

            nesting_rules = {
                ["package.json"] = {
                    pattern = "^package%.json$", -- <-- Lua pattern
                    files = {
                        "package-lock.json",
                        "yarn*",
                        "pnpm-*.yaml",
                        ".npmrc",
                    }, -- <-- accept glob patterns
                },
                ["tsx"] = {
                    pattern = "(.+)%.tsx$",
                    files = {
                        "%1.*.ts",
                        "%1.*.tsx",
                        "%1.*.css",
                        "%1.*.scss",
                        "%1.*.mdx",
                    },
                },
                ["ts"] = {
                    pattern = "(.+)%.ts$",
                    files = {
                        "%1.*.ts",
                        "%1.*.tsx",
                        "%1.*.css",
                        "%1.*.scss",
                        "%1.*.mdx",
                    },
                },
                ["docker"] = {
                    pattern = "^dockerfile$",
                    ignore_case = true,
                    files = {
                        ".dockerignore",
                        "docker-compose.*",
                        "dockerfile*",
                    },
                },
                ["tsconfig"] = {
                    pattern = "(.+)%.json$",
                    files = {
                        "%1.*.json",
                    },
                },
            },
        },
    },
}
