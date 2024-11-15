return {
    {
        "nvim-telescope/telescope.nvim",
        -- tag = "0.1.6",
        -- or
        -- branch = "0.1.x",
        dependencies = {
            { "nvim-lua/plenary.nvim" },
            { "nvim-tree/nvim-web-devicons" },
            -- { "nvim-telescope/telescope-ui-select.nvim" },
            { "princejoogie/dir-telescope.nvim" },
            {
                "nvim-telescope/telescope-live-grep-args.nvim",
                version = "^1.0.0",
            },
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
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

            local fileIgnorePatterns = {
                "%.git/",
                -- disabling it as it was blocking lsp_references,
                -- it doesn't seem to affect file_search, it is still being ignored
                -- "node_modules",
                "%.next/",
                "%.playwright-state",
                "%.turbo/",
                "%.yarn/",
                "/out/",
                "playwright%-report",
                "/storybook%-static",
                "test%-results",
                -- "/vendor/", -- disabled as it was Blocking PHP lsp
                "y4m",
                "%.veedio",
            }

            -- forcing node_modules to be ignored for normal grep search
            local fileIgnorePatternsWithNodeModules = {
                unpack(fileIgnorePatterns),
            }

            table.insert(fileIgnorePatternsWithNodeModules, "node_modules/")
            table.insert(fileIgnorePatternsWithNodeModules, "/build/")
            table.insert(fileIgnorePatternsWithNodeModules, "/dist/")
            table.insert(
                fileIgnorePatternsWithNodeModules,
                "package%-lock.json"
            )
            table.insert(fileIgnorePatternsWithNodeModules, "pnpm%-lock.yaml")
            table.insert(fileIgnorePatternsWithNodeModules, "yarn%.lock")
            table.insert(fileIgnorePatternsWithNodeModules, "/vendor/")

            local function send_all_to_quickfix_and_open_trouble(prompt_bufnr)
                actions.send_to_qflist(prompt_bufnr)
                vim.cmd("Trouble quickfix open")
            end

            local function selected_to_quickfix_and_open_trouble(prompt_bufnr)
                actions.send_selected_to_qflist(prompt_bufnr)
                vim.cmd("Trouble quickfix open")
            end

            local lgaQuotePrompt = lga_actions.quote_prompt({
                trim = true,
            })

            local lgaAddIglob = lga_actions.quote_prompt({
                trim = true,
                postfix = " --iglob ",
            })

            local function quote_prompt(prompt_bufnr)
                return lgaQuotePrompt(prompt_bufnr)
            end

            local function add_iglob(prompt_bufnr)
                local picker = action_state.get_current_picker(prompt_bufnr)
                local prompt = picker:_get_prompt()

                if
                    string.find(prompt, " -F") or string.find(prompt, "--iglob")
                then
                    picker:set_prompt(prompt .. " --iglob ")
                else
                    lgaAddIglob(prompt_bufnr)
                end
            end

            local function exclude_test_files(prompt_bufnr)
                add_iglob(prompt_bufnr)

                local picker = action_state.get_current_picker(prompt_bufnr)
                local prompt = picker:_get_prompt()
                picker:set_prompt(
                    prompt .. "!**.spec.* --iglob !**.test.* --iglob !**/r2/**"
                )
            end

            telescope.setup({
                defaults = {
                    color_devicons = true,
                    cache_picker = {
                        num_pickers = 20, -- your preferred number here, values up to 100 should be perfectly fine; likely even much higher
                    },
                    -- this has to be a valid lua regex:
                    -- https://github.com/nvim-telescope/telescope.nvim/blob/35f94f0ef32d70e3664a703cefbe71bd1456d899/doc/telescope.txt#L643
                    file_ignore_patterns = fileIgnorePatterns,
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

                    path_display = {
                        "filename_first",
                    },

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
                            ["<C-c>"] = actions.close, -- I don't know why this is not the default
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
                        -- initial_mode = "normal",
                        file_ignore_patterns = fileIgnorePatternsWithNodeModules,
                    },

                    lsp_references = {
                        -- initial_mode = "normal",
                        fname_width = 0.99,
                        -- path_display = {
                        --     "smart",
                        -- },
                        wrap_results = true,
                    },

                    lsp_definitions = {
                        -- initial_mode = "normal",
                        fname_width = 0.99,
                        -- path_display = {
                        --     "smart",
                        -- },
                        wrap_results = true,
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
                                            "DiffviewOpen origin/HEAD...%s --imply-local",
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

                    -- https://github.com/nvim-telescope/telescope-fzf-native.nvim?tab=readme-ov-file#telescope-setup-and-configuration
                    fzf = {
                        fuzzy = true, -- false will only do exact matching
                        override_generic_sorter = true, -- override the generic sorter
                        override_file_sorter = true, -- override the file sorter
                        case_mode = "smart_case", -- or "ignore_case" or "respect_case"
                        -- the default case_mode is "smart_case"
                    },

                    live_grep_args = {
                        file_ignore_patterns = fileIgnorePatternsWithNodeModules,
                        auto_quoting = true, -- enable/disable auto-quoting
                        -- define mappings, e.g.
                        mappings = { -- extend mappings
                            i = {
                                ["<C-k>"] = quote_prompt,
                                -- <C-i> is the same as `<Tab>` for historical reasons https://github.com/neovim/neovim/issues/5916
                                ["<C-l>"] = add_iglob,
                                ["<C-e>"] = exclude_test_files,
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
                live_grep = telescope.extensions.live_grep_args.live_grep_args,
            })

            vim.keymap.set(
                "n",
                "<leader>f",
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

            vim.keymap.set("n", "<leader>ba", function()
                builtin.buffers({
                    only_cwd = false,
                    -- cwd_only = false,
                })
            end, { desc = "List buffers open" })

            vim.keymap.set(
                "n",
                "<leader>o",
                builtin.oldfiles,
                { desc = "Find recently opened files" }
            )

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
                { desc = "[T]elescope [r]esume last picker" }
            )

            -- disabled in favor my custom one with args below
            -- vim.keymap.set("n", "<leader>sd", "<cmd>GrepInDirectory<CR>", {
            --     noremap = true,
            --     silent = true,
            --     desc = "Grep Search in directory",
            -- })

            vim.keymap.set(
                "n",
                "<leader>cm",
                "<cmd>Telescope filetypes<CR>",
                { noremap = true, silent = true, desc = "Change file type" }
            )

            vim.keymap.set(
                "n",
                "<leader>sd",
                "<CMD>Telescope dir live_grep<CR>",
                {
                    noremap = true,
                    silent = true,
                    desc = "Search in directory with Args",
                }
            )

            local liveGrepWithGlob = function(glob)
                -- live_grep_args doesn't accept multiple globs
                -- https://github.com/BurntSushi/ripgrep/issues/875
                telescope.extensions.live_grep_args.live_grep_args({
                    prompt_title = 'Live Grep (Args) - glob "' .. glob .. '"',
                    -- adding glob as text, so it can be edited
                    default_text = "--iglob " .. glob .. " ",
                })
            end

            local lastGlob = "**/*"

            -- Asks for a glob and then opens a live grep that searches only on files matching the glob
            vim.api.nvim_create_user_command("LiveGrepWithGlob", function(ctx)
                if string.len(ctx.args) > 0 then
                    lastGlob = ctx.args
                    liveGrepWithGlob(ctx.args)
                else
                    vim.ui.input({
                        prompt = "Glob: ",
                        completion = "file",
                        default = lastGlob,
                    }, function(glob)
                        if not glob or glob == "" then
                            return
                        end
                        lastGlob = glob
                        liveGrepWithGlob(glob)
                    end)
                end
            end, {
                nargs = "*",
                complete = "file",
                desc = "Live grep with glob",
            })

            vim.keymap.set("n", "<leader>sg", "<cmd>LiveGrepWithGlob<CR>", {
                desc = "Live Grep with file glob",
            })
        end,
    },
}
