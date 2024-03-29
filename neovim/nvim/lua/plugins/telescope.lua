return {
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        -- or                            , branch = '0.1.x',
        dependencies = {
            { "nvim-lua/plenary.nvim" },
            -- { "nvim-telescope/telescope-ui-select.nvim" },
            { "princejoogie/dir-telescope.nvim" },
            {
                "nvim-telescope/telescope-live-grep-args.nvim",
                version = "^1.0.0",
            },
        },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")
            local utils = require("telescope.utils")
            local lga_actions = require("telescope-live-grep-args.actions")

            -- https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes#file-and-text-search-in-hidden-files-and-directories
            local telescopeConfig = require("telescope.config")
            -- Clone the default Telescope configuration
            if not unpack then
                unpack = table.unpack
            end

            local vimgrep_arguments = {
                unpack(telescopeConfig.values.vimgrep_arguments),
            }

            table.insert(vimgrep_arguments, "--smart-case")
            -- I want to search in hidden/dot files.
            table.insert(vimgrep_arguments, "--hidden")
            -- I don't want to search in the `.git` directory.
            table.insert(vimgrep_arguments, "--glob")
            table.insert(vimgrep_arguments, "!**/.git/*")

            local function send_all_to_quickfix_and_open_trouble(prompt_bufnr)
                actions.send_to_qflist(prompt_bufnr)
                vim.cmd("Trouble quickfix")
            end

            local function selected_to_quickfix_and_open_trouble(prompt_bufnr)
                actions.send_selected_to_qflist(prompt_bufnr)
                vim.cmd("Trouble quickfix")
            end

            telescope.setup({
                defaults = {
                    color_devicons = true,
                    cache_picker = {
                        num_pickers = 20, -- your preferred number here, values up to 100 should be perfectly fine; likely even much higher
                    },
                    file_ignore_patterns = {
                        "\\.git",
                        -- disabling it as it was blocking lsp_references,
                        -- it doesn't seem to affect file_search, it is still being ignored
                        -- "node_modules",
                        "vendor",
                        "build",
                        "dist",
                        "yarn.lock",
                        "package-lock.json",
                        "pnpm-lock.yaml",
                        ".turbo",
                        ".yarn",
                        ".next",
                        "out/",
                        "playwright-report",
                        ".playwright-state",
                        "test-results",
                        "y4m",
                    },
                    vimgrep_arguments = vimgrep_arguments,
                    sorting_strategy = "ascending",
                    wrap_results = true,

                    layout_config = {
                        vertical = {
                            -- width = 0.95,
                        },
                        horizontal = {
                            width = 0.95,
                            -- preview_width = 0.35,
                            preview_width = 80,
                            fname_width = 100,
                            prompt_position = "top",
                            -- preview_cutoff = 80,
                        },
                        center = {
                            width = 0.70,
                        },
                    },

                    -- path_display = {
                    --     "smart",
                    -- },

                    preview = {
                        treesitter = true,
                    },

                    mappings = {
                        i = {
                            -- map actions.which_key to <C-h> (default: <C-/>)
                            -- actions.which_key shows the mappings for your picker,
                            -- e.g. git_{create, delete, ...}_branch for the git_branches picker
                            ["<C-h>"] = actions.which_key,
                            -- Replace mappings to send to quickfix as Alt doesn't work well on Mac, and Alt + q is already mapped to <Esc>
                            ["<C-S-q>"] = send_all_to_quickfix_and_open_trouble,
                            ["<C-q>"] = selected_to_quickfix_and_open_trouble,
                        },
                        n = {
                            ["q"] = actions.close,
                            ["<C-h>"] = actions.which_key,
                            ["<C-S-q>"] = send_all_to_quickfix_and_open_trouble,
                            ["<C-q>"] = selected_to_quickfix_and_open_trouble,
                        },
                    },
                },

                pickers = {
                    oldfiles = {
                        -- `cwd` will be the directory where Telescope started.
                        cwd_only = true,
                        initial_mode = "normal",
                    },

                    lsp_references = {
                        initial_mode = "normal",
                        -- fname_width = 0.70,
                    },

                    lsp_definitions = {
                        initial_mode = "normal",
                    },

                    find_files = {
                        -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
                        find_command = {
                            "rg",
                            -- "--color=never",
                            -- "--no-heading",
                            -- "--with-filename",
                            -- "--line-number",
                            -- "--column",
                            -- "--smart-case",
                            "--files",
                            "--hidden",
                            "--glob",
                            "!**/.git/*",
                        },
                    },

                    git_files = { show_untracked = true },

                    git_branches = {
                        mappings = {
                            i = {
                                -- @TODO: change this mapping to a more intuitive one
                                -- Maybe <D-c> Mac's command + c as in [c]ompare
                                ["<C-a>"] = function(prompt_bufnr)
                                    local selection =
                                        action_state.get_selected_entry()

                                    if selection == nil then
                                        utils.notify("git_compare_branches", {
                                            msg = "No branch selected",
                                            level = "WARN",
                                        })
                                        return
                                    end

                                    actions.close(prompt_bufnr)

                                    vim.cmd(
                                        string.format(
                                            "DiffviewOpen %s...HEAD --imply-local",
                                            selection.value
                                        )
                                    )
                                end,
                            },
                        },
                    },
                },
                extensions = {
                    -- Disabling from now, as I don't want code actions to be on the pickers cache
                    -- ["ui-select"] = {
                    --     require("telescope.themes").get_dropdown({}),
                    -- },

                    live_grep_args = {
                        auto_quoting = true, -- enable/disable auto-quoting
                        -- define mappings, e.g.
                        mappings = { -- extend mappings
                            i = {
                                ["<C-k>"] = lga_actions.quote_prompt(),
                                ["<C-i>"] = lga_actions.quote_prompt({
                                    postfix = " --iglob ",
                                }),
                            },
                        },
                        -- ... also accepts theme settings, for example:
                        -- theme = "dropdown", -- use dropdown theme
                        -- theme = { }, -- use own theme spec
                        -- layout_config = { mirror=true }, -- mirror preview pane
                    },
                },
            })

            -- telescope.load_extension("ui-select")
            telescope.load_extension("live_grep_args")
            telescope.load_extension("dir")

            local builtin = require("telescope.builtin")

            require("dir-telescope").setup({
                -- these are the default options set
                hidden = true,
                no_ignore = false,
                show_preview = true,
            })

            vim.keymap.set(
                "n",
                "<leader>f",
                -- builtin.live_grep, -- disable to allow adding args
                telescope.extensions.live_grep_args.live_grep_args,
                { desc = "Live Grep all files" }
            )

            vim.keymap.set(
                "v",
                "<leader>f",
                require("telescope-live-grep-args.shortcuts").grep_visual_selection,
                { desc = "Live Grep current selection on all files" }
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
                "<leader>bo",
                builtin.buffers,
                { desc = "List buffers open" }
            )

            vim.keymap.set(
                "n",
                "<leader>o",
                builtin.oldfiles,
                { desc = "Find recently opened files" }
            )

            vim.keymap.set("n", "<leader>sg", function()
                builtin.grep_string({ search = vim.fn.input("Grep > ") })
            end, {
                desc = "Input a string to Grep",
            })

            vim.keymap.set("n", "<leader>/", function()
                -- You can pass additional configuration to telescope to change theme, layout, etc.
                builtin.current_buffer_fuzzy_find(
                    -- require("telescope.themes").get_dropdown({
                    --     -- winblend = 10,
                    --     -- previewer = true,
                    --     -- layout_strategy = "vertical",
                    --     -- layout_config = {
                    --     --     width = 80,
                    --     -- },
                    -- })
                )
            end, {
                desc = "[/] Fuzzily search in current buffer on Modal with results",
            })

            vim.keymap.set(
                "n",
                "<leader>tk",
                builtin.keymaps,
                { desc = "[T]elescope list all [k]eymaps" }
            )

            vim.keymap.set(
                "n",
                "<leader>th",
                builtin.help_tags,
                { desc = "[T]elescope [h]elp tags" }
            )

            vim.keymap.set(
                "n",
                "<leader>tp",
                builtin.pickers,
                { desc = "[T]elescope list all [p]ickers" }
            )

            vim.keymap.set(
                "n",
                "<leader>tr",
                builtin.resume,
                { desc = "[T]elescope list all [r]esume" }
            )

            vim.keymap.set(
                "n",
                "<leader>sd",
                "<cmd>GrepInDirectory<CR>",
                { noremap = true, silent = true }
            )

            vim.api.nvim_create_user_command("LiveGrepWithGlob", function(ctx)
                -- another option would be use vim.ui.input:
                -- vim.ui.input({ prompt = "Glob: ", completion = "file", default = "**/*." })
                -- but it doesn't seem to auto-complete the glob while typing

                vim.ui.input({
                    prompt = "Glob: ",
                    completion = "file",
                    default = "**/*",
                }, function(glob)
                    builtin.live_grep({
                        vimgrep_arguments = {
                            "rg",
                            "--color=never",
                            "--no-heading",
                            "--with-filename",
                            "--line-number",
                            "--column",
                            "--smart-case",
                            "--glob=" .. (glob or ""),
                            -- @TODO: how to add negative globs? like --glob='!**/node_modules/*'
                            -- and also multiple globs
                            -- first test if a file in .git will work,
                            -- then add a second --glob='!**/.git/*' to check if it works
                            -- search about RD arguments
                        },
                    })
                end)
            end, {
                -- nargs = "+",
                -- complete = "file",
                desc = "Live grep with glob",
            })
        end,
    },
}
