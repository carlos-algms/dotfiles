local P = {}

local M = {
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
                version = "^1.1.0",
            },
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
            },
            "3rd/image.nvim", -- added to support image preview
        },

        cmd = { "Telescope" },

        keys = {

            {

                "<C-p>",
                "<cmd>Telescope find_files<CR>",
                desc = "Find files by name in the current folder",
                silent = true,
            },

            {
                "<leader>pg",
                "<cmd>Telescope git_files<CR>",
                desc = "Find files tracked by git",
                silent = true,
            },

            {
                "<leader>f",
                "<cmd>Telescope live_grep_args<CR>",
                desc = "Live Grep all files",
                silent = true,
            },

            {
                "<leader>f",
                function()
                    require("telescope-live-grep-args.shortcuts").grep_visual_selection()
                end,
                desc = "Live Grep current selection on all files",
                silent = true,
                mode = "v",
            },

            {
                "<leader>bo",
                "<cmd>Telescope buffers only_cwd=true<CR>",
                desc = "List buffers open",
                silent = true,
            },

            {
                "<leader>ba",
                "<cmd>Telescope buffers only_cwd=false<CR>",
                desc = "List all buffers open everywhere",
                silent = true,
            },

            {
                "<leader>o",
                "<cmd>Telescope oldfiles only_cwd=true<CR>",
                desc = "Find recently opened files",
                silent = true,
            },

            {
                "<leader>O",
                "<cmd>Telescope oldfiles only_cwd=false prompt_title=Oldfiles\\ Everywhere<CR>",
                desc = "Find All recently opened files",
                silent = true,
            },

            {
                "<leader>/",
                "<cmd>Telescope current_buffer_fuzzy_find<CR>",
                desc = "[/] Fuzzy search in current buffer",
                silent = true,
            },

            {
                "<leader>tk",
                "<cmd>Telescope keymaps<CR>",
                desc = "List all keymaps",
                silent = true,
            },

            {
                "<leader>th",
                "<cmd>Telescope help_tags<CR>",
                desc = "Search help docs",
                silent = true,
            },

            {
                "<leader>tp",
                "<cmd>Telescope pickers<CR>",
                desc = "List telescope pickers history",
                silent = true,
            },

            {
                "<leader>tr",
                "<cmd>Telescope resume<CR>",
                desc = "Telescope resume last picker",
                silent = true,
            },

            {
                "<leader>cm",
                "<cmd>Telescope filetypes<CR>",
                desc = "Change file type",
                silent = true,
            },

            {
                "<leader>sd",
                "<cmd>Telescope dir live_grep<CR>",
                desc = "Search in directory with Args",
                silent = true,
            },

            {
                "<leader>sg",
                function()
                    P.liveGrepWithGlob.live_grep_with_glob()
                end,
                desc = "Live Grep with file glob",
                silent = true,
            },

            {
                "<leader>gB",
                "<cmd>Telescope git_branches<CR>",
                mode = "n",
                desc = "Show git branches",
                silent = true,
            },

            {
                "<leader>gl",
                "<cmd>Telescope git_status<CR>",
                mode = "n",
                desc = "Show git status as a list",
                silent = true,
            },
        },

        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")

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
                            ["<C-Space>"] = actions.to_fuzzy_refine,
                        },
                        n = {
                            ["<C-c>"] = actions.close, -- I don't know why this is not the default
                            ["q"] = actions.close,
                            ["<C-h>"] = actions.which_key,
                        },
                    },
                },

                pickers = {
                    buffers = {
                        sort_mru = true,
                    },

                    oldfiles = {
                        -- `cwd` will be the directory where Telescope started.
                        -- cwd_only = true,
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
                    live_grep_args = P.getLiveGrepArgsSettings(
                        fileIgnorePatternsWithNodeModules
                    ),
                },
            })

            P.setupGitFilesPicker()
            P.setupTroubleInTelescope()
            P.setupImagePreviewInTelescope()

            -- telescope.load_extension("ui-select")
            telescope.load_extension("live_grep_args")
            telescope.load_extension("dir")
            telescope.load_extension("fzf")

            require("dir-telescope").setup({
                -- these are the default options set
                hidden = true,
                no_ignore = false,
                show_preview = true,
                live_grep = function(opts)
                    opts.prompt_title = "Live grep Args on "
                        .. table.concat(opts.search_dirs, ", ")
                    telescope.extensions.live_grep_args.live_grep_args(opts)
                end,
            })
        end,
    },
}

P.liveGrepWithGlob = {
    lastGlob = "**/*",
    live_grep_with_glob = function()
        vim.ui.input({
            prompt = "Glob: ",
            completion = "file",
            default = P.liveGrepWithGlob.lastGlob,
        }, function(glob)
            if not glob or glob == "" then
                return
            end
            P.liveGrepWithGlob.lastGlob = glob
            require("telescope").extensions.live_grep_args.live_grep_args({
                prompt_title = 'Live Grep (Args) - glob "' .. glob .. '"',
                -- adding glob as text, so it can be edited
                default_text = "--iglob " .. glob .. " ",
            })
        end)
    end,
}

--- @param fileIgnorePatternsWithNodeModules table
function P.getLiveGrepArgsSettings(fileIgnorePatternsWithNodeModules)
    local action_state = require("telescope.actions.state")
    local lga_actions = require("telescope-live-grep-args.actions")

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

        if string.find(prompt, " -F") or string.find(prompt, "--iglob") then
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

    return {
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
    }
end

function P.setupGitFilesPicker()
    local function compare_branch_to_head(prompt_bufnr)
        local selection =
            require("telescope.actions.state").get_selected_entry()

        if selection == nil then
            require("telescope.utils").notify("git_compare_branches", {
                msg = "No branch selected",
                level = "WARN",
            })
            return
        end

        require("telescope.actions").close(prompt_bufnr)

        vim.cmd(
            string.format(
                "DiffviewOpen origin/HEAD...%s --imply-local",
                selection.value
            )
        )
    end

    local config = require("telescope.config")
    local newConfig = {
        git_branches = {
            mappings = {
                i = {
                    ["<C-f>"] = compare_branch_to_head,
                },
            },
        },
    }

    config.pickers =
        vim.tbl_deep_extend("force", config.pickers or {}, newConfig)
end

function P.setupTroubleInTelescope()
    local config = require("telescope.config").values
    local actions = require("telescope.actions")

    local function send_all_to_quickfix_and_open_trouble(prompt_bufnr)
        actions.send_to_qflist(prompt_bufnr)
        vim.cmd("Trouble quickfix open")
    end

    local function selected_to_quickfix_and_open_trouble(prompt_bufnr)
        actions.send_selected_to_qflist(prompt_bufnr)
        vim.cmd("Trouble quickfix open")
    end

    local new_mappings = {
        i = {
            ["<C-S-q>"] = send_all_to_quickfix_and_open_trouble,
            ["<C-q>"] = selected_to_quickfix_and_open_trouble,
        },
        n = {
            ["<C-S-q>"] = send_all_to_quickfix_and_open_trouble,
            ["<C-q>"] = selected_to_quickfix_and_open_trouble,
        },
    }

    config.mappings = vim.tbl_deep_extend(
        "force",
        vim.F.if_nil(config.mappings, {}),
        new_mappings
    )
end

function P.setupImagePreviewInTelescope()
    local status, image_api = pcall(require, "image")
    if not status then
        return
    end
    local supported_images =
        { "svg", "png", "jpg", "jpeg", "gif", "webp", "avif" }

    local is_supported_image = function(filepath)
        local extension = vim.fn.fnamemodify(filepath, ":e")
        return vim.tbl_contains(supported_images, extension)
    end

    local function telescope_image_preview()
        local from_entry = require("telescope.from_entry")
        local Path = require("plenary.path")
        local conf = require("telescope.config").values
        local Previewers = require("telescope.previewers")

        local previewers = require("telescope.previewers")

        local is_image_preview = false
        local image = nil
        local last_file_path = ""

        local delete_image = function()
            if not image then
                return
            end

            image:clear()

            is_image_preview = false
        end

        local create_image = function(filepath, winid, bufnr)
            image = image_api.hijack_buffer(filepath, winid, bufnr)

            if not image then
                return
            end

            vim.schedule(function()
                image:render()
            end)

            is_image_preview = true
        end

        local function defaulter(f, default_opts)
            default_opts = default_opts or {}
            return {
                new = function(opts)
                    if conf.preview == false and not opts.preview then
                        return false
                    end
                    opts.preview = type(opts.preview) ~= "table" and {}
                        or opts.preview
                    if type(conf.preview) == "table" then
                        for k, v in pairs(conf.preview) do
                            opts.preview[k] = vim.F.if_nil(opts.preview[k], v)
                        end
                    end
                    return f(opts)
                end,
                __call = function()
                    local ok, err = pcall(f(default_opts))
                    if not ok then
                        error(debug.traceback(err))
                    end
                end,
            }
        end

        -- NOTE: Add teardown to cat previewer to clear image when close Telescope
        local file_previewer = defaulter(function(opts)
            opts = opts or {}
            local cwd = opts.cwd or vim.fn.getcwd()
            return Previewers.new_buffer_previewer({
                title = "File Preview",
                dyn_title = function(_, entry)
                    return Path:new(from_entry.path(entry, true)):normalize(cwd)
                end,

                get_buffer_by_name = function(_, entry)
                    return from_entry.path(entry, true)
                end,

                define_preview = function(self, entry, _)
                    local p = from_entry.path(entry, true)
                    if p == nil or p == "" then
                        return
                    end

                    conf.buffer_previewer_maker(p, self.state.bufnr, {
                        bufname = self.state.bufname,
                        winid = self.state.winid,
                        preview = opts.preview,
                    })
                end,

                teardown = function(_)
                    if is_image_preview then
                        delete_image()
                    end
                end,
            })
        end, {})

        local buffer_previewer_maker = function(filepath, bufnr, opts)
            -- NOTE: Clear image when preview other file
            if is_image_preview and last_file_path ~= filepath then
                delete_image()
            end

            last_file_path = filepath

            if is_supported_image(filepath) then
                create_image(filepath, opts.winid, bufnr)
            else
                previewers.buffer_previewer_maker(filepath, bufnr, opts)
            end
        end

        return {
            buffer_previewer_maker = buffer_previewer_maker,
            file_previewer = file_previewer.new,
        }
    end

    local image_preview = telescope_image_preview()

    local config = require("telescope.config")
    local tables = require("helpers.tables")

    tables.deep_extend(config.values, {
        file_previewer = image_preview.file_previewer,
        buffer_previewer_maker = image_preview.buffer_previewer_maker,
    })

    -- enable line numbers on telescope previewer pane
    -- it's here because I need to check for image files
    vim.api.nvim_create_autocmd("User", {
        pattern = "TelescopePreviewerLoaded",
        group = vim.api.nvim_create_augroup(
            "TelescopePreviewerGroup",
            { clear = true }
        ),
        callback = function(event)
            if not is_supported_image(event.data.bufname) then
                vim.cmd("setlocal number")
            end
        end,
    })
end

return M
