return {
    {
        "nvim-telescope/telescope-dap.nvim",
        dependencies = "mfussenegger/nvim-dap",
    },
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        -- or                            , branch = '0.1.x',
        dependencies = {
            { "nvim-lua/plenary.nvim" },
            { "nvim-telescope/telescope-ui-select.nvim" },
            { "nvim-telescope/telescope-dap.nvim" },
        },
        config = function()
            local telescope = require("telescope")

            -- https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes#file-and-text-search-in-hidden-files-and-directories
            local telescopeConfig = require("telescope.config")
            -- Clone the default Telescope configuration
            if not unpack then
                unpack = table.unpack
            end

            local vimgrep_arguments = {
                unpack(telescopeConfig.values.vimgrep_arguments),
            }

            -- I want to search in hidden/dot files.
            table.insert(vimgrep_arguments, "--hidden")
            -- I don't want to search in the `.git` directory.
            table.insert(vimgrep_arguments, "--glob")
            table.insert(vimgrep_arguments, "!**/.git/*")

            telescope.setup({
                defaults = {
                    file_ignore_patterns = {
                        "node_modules",
                        "build",
                        "dist",
                        "yarn.lock",
                    },
                    vimgrep_arguments = vimgrep_arguments,
                },
                pickers = {
                    find_files = {
                        -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
                        find_command = {
                            "rg",
                            "--files",
                            "--hidden",
                            "--glob",
                            "!**/.git/*",
                        },
                    },
                },
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                    },
                },
            })

            telescope.load_extension("dap")
            telescope.load_extension("ui-select")

            local builtin = require("telescope.builtin")

            vim.keymap.set(
                "n",
                "<leader>pl",
                builtin.live_grep,
                { desc = "[P]roject wide [L]ive grep search" }
            )
            vim.keymap.set(
                "n",
                "<C-p>",
                builtin.find_files,
                { desc = "Find files by name in the current folder" }
            )
            vim.keymap.set(
                "n",
                "<leader>pg",
                builtin.git_files,
                { desc = "[P]roject wide [G]it files fuzy finder" }
            )
            vim.keymap.set(
                "n",
                "<leader>pb",
                builtin.buffers,
                { desc = "Find current open buffers" }
            )
            vim.keymap.set(
                "n",
                "<leader>po",
                builtin.oldfiles,
                { desc = "Find recently opened files" }
            )

            vim.keymap.set("n", "<leader>ps", function()
                builtin.grep_string({ search = vim.fn.input("Grep > ") })
            end, {
                desc = "[ps] Grep string in the current folder and open results in a Modal",
            })

            vim.keymap.set("n", "<leader>/", function()
                -- You can pass additional configuration to telescope to change theme, layout, etc.
                builtin.current_buffer_fuzzy_find(
                    require("telescope.themes").get_dropdown({
                        winblend = 10,
                        previewer = false,
                    })
                )
            end, {
                desc = "[/] Fuzzily search in current buffer on Modal with results",
            })

            -- LSP
            vim.keymap.set(
                "n",
                "gr",
                builtin.lsp_references,
                { desc = "List [r]eferences using Telescope" }
            )
        end,
    },
}
