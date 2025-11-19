return {
    {
        "pwntester/octo.nvim",
        -- dir = "/Users/carlos/projects/octo.nvim",
        enabled = not vim.g.is_ssh,
        -- event = "VeryLazy",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        cmd = { "Octo" },
        keys = {
            {
                "<leader>gp",
                "<cmd>Octo pr list<CR>",
                desc = "List pull-requests with Octo",
            },
            {
                "<leader>gP",
                "<cmd>Octo pr create<CR>",
                desc = "Create a pull-request using Octo",
            },
        },
        config = function()
            require("octo").setup({
                enable_builtin = true,
                default_remote = { "origin", "upstream" },
                picker = "telescope",
                comment_icon = "󰆈 ",
                suppress_missing_scope = {
                    projects_v2 = true,
                },
            })
        end,
    },

    {
        "lewis6991/gitsigns.nvim",

        event = "VeryLazy",

        keys = {
            {
                "<leader>gb",
                "<CMD>Gitsigns blame<CR>",
                mode = "n",
                desc = "Git Blame",
            },
        },

        init = function()
            local function jumpToNextHunk()
                if vim.wo.diff then
                    vim.cmd.normal({ "]c", bang = true })
                else
                    vim.cmd("Gitsigns next_hunk")
                end
            end

            local function jumpToPrevHunk()
                if vim.wo.diff then
                    vim.cmd.normal({ "[c", bang = true })
                else
                    vim.cmd("Gitsigns prev_hunk")
                end
            end

            vim.keymap.set("n", ")", jumpToNextHunk, {
                desc = "next change hunk",
            })

            -- I'm remapping parens, as I never use them to navigate paragraphs
            vim.keymap.set("n", "]c", jumpToNextHunk, {
                desc = "next change hunk (same as ]c)",
            })

            vim.keymap.set("n", "[c", jumpToPrevHunk, {
                desc = "prev change hunk",
            })

            vim.keymap.set("n", "(", jumpToPrevHunk, {
                desc = "prev change hunk (same as [c)",
            })
        end,

        config = function()
            local gitsigns = require("gitsigns")

            gitsigns.setup({
                diff_opts = {
                    -- https://github.com/lewis6991/gitsigns.nvim/blob/main/doc/gitsigns.txt
                    internal = true,
                    algorithm = "histogram",
                    indent_heuristic = true,
                    ignore_whitespace = true,
                    ignore_whitespace_change = true,
                    ignore_whitespace_change_at_eol = true,
                    ignore_blank_lines = false,
                },
                current_line_blame = false, -- I don't think he virtual text is useful
                current_line_blame_opts = {
                    ignore_whitespace = true,
                },

                -- word_diff = true,

                ---@type vim.api.keyset.win_config
                preview_config = {
                    -- Options passed to nvim_open_win
                    style = "minimal",
                    relative = "cursor",
                    row = -1,
                    col = 2,
                    border = "rounded",
                },

                on_attach = function(bufnr)
                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    map(
                        "n",
                        "<leader>gv",
                        ":Gitsigns preview_hunk<CR>",
                        { desc = "Show hunk preview", silent = true }
                    )

                    map(
                        { "n", "v" },
                        "<leader>g-",
                        ":Gitsigns reset_hunk<CR>",
                        { desc = "Reset hunk", silent = true }
                    )

                    map(
                        { "n", "v" },
                        "<leader>g=",
                        "<cmd>Gitsigns stage_hunk<CR>",
                        { desc = "Stage hunk", silent = true }
                    )
                end,
            })
        end,
    },

    {
        "sindrets/diffview.nvim",
        enabled = true,

        cmd = {
            "DiffviewOpen",
            "DiffviewFileHistory",
        },

        keys = {
            {
                "<leader>gcm",
                function()
                    -- Try origin first (prefer remote), fallback to local main/master
                    local branch = vim.fn
                        .system(
                            "(git rev-parse --verify --quiet origin/HEAD >/dev/null 2>&1 && "
                                .. "git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@') || "
                                .. "(git rev-parse --verify --quiet refs/heads/main >/dev/null 2>&1 && echo main) || "
                                .. "(git rev-parse --verify --quiet refs/heads/master >/dev/null 2>&1 && echo master)"
                        )
                        :gsub("%s+", "")

                    if branch == "" then
                        vim.notify(
                            "No main/master branch or origin remote found",
                            vim.log.levels.ERROR
                        )
                        return
                    end

                    -- Check if origin/<branch> exists, use it; otherwise use local
                    local origin_check = vim.fn.system(
                        "git rev-parse --verify --quiet origin/"
                            .. branch
                            .. " 2>/dev/null"
                    )

                    local base = (origin_check ~= "") and ("origin/" .. branch)
                        or branch

                    vim.cmd("DiffviewOpen " .. base .. "...HEAD --imply-local")
                end,
                mode = { "n" },
                desc = "Compare current branch to main/master",
                silent = true,
            },

            {
                "<leader>gs",
                "<cmd>DiffviewOpen<cr>",
                mode = "n",
                desc = "Git status DiffView",
                silent = true,
            },
            {
                "<leader>gh",
                "<cmd>DiffviewFileHistory % <CR>",
                mode = "n",
                desc = "Show Git History for the current file",
            },
            {
                "<leader>gH",
                "<cmd>DiffviewFileHistory <CR>",
                mode = "n",
                desc = "Show Git History",
            },
        },

        config = function()
            local actions = require("diffview.actions")
            local quitDiffViewKeymap = {
                "n",
                "gq",
                "<cmd>tabclose<cr>",
                { desc = "Close the Diffview" },
            }

            local commitKeyMap = {
                "n",
                "cc",
                "<cmd>tab Git commit<cr>",
                { desc = "Commit staged files" },
            }

            local commitNoVerifyKeyMap = {
                "n",
                "cC",
                "<cmd>tab Git commit --no-verify<cr>",
                { desc = "Commit staged files with --no-verify" },
            }

            local nextItemKeymap_ = {
                "n",
                "J", -- TODO: do the same as select entry to focus on the first hunk
                actions.select_next_entry,
                { desc = "Open the diff for the next file" },
            }

            local prevItemKeymap_ = {
                "n",
                "K",
                actions.select_prev_entry,
                { desc = "Open the diff for the previous file" },
            }

            require("diffview").setup({
                -- enabled because it wasn't diffing generated files
                diff_binaries = false,
                default_args = {
                    DiffviewOpen = { "--imply-local" },
                },
                file_panel = {
                    listing_style = "list",
                    win_config = {
                        position = "bottom",
                        height = 10,
                    },
                },
                keymaps = {
                    disable_defaults = false, -- Disable the default keymaps
                    file_panel = {
                        quitDiffViewKeymap,
                        commitKeyMap,
                        commitNoVerifyKeyMap,
                        nextItemKeymap_,
                        prevItemKeymap_,

                        {
                            "n",
                            "<cr>",
                            function()
                                actions.select_entry()
                                vim.cmd("wincmd 1w")
                                vim.cmd("norm gg")
                                vim.cmd("wincmd 2w")
                                vim.cmd("norm gg]c")
                            end,
                            { desc = "Open the diff for the selected entry" },
                        },
                        {
                            "n",
                            "<c-b>",
                            actions.scroll_view(-0.25),
                            { desc = "Scroll the view up" },
                        },
                        {
                            "n",
                            "<c-f>",
                            actions.scroll_view(0.25),
                            { desc = "Scroll the view down" },
                        },
                    },
                    view = {
                        quitDiffViewKeymap,
                        commitKeyMap,
                        commitNoVerifyKeyMap,
                        nextItemKeymap_,
                        prevItemKeymap_,

                        {
                            "n",
                            "s",
                            actions.toggle_stage_entry,
                            { desc = "Stage / unstage the selected entry" },
                        },
                        {
                            { "n", "v" },
                            "=",
                            ":Gitsigns stage_hunk<CR>",
                            { desc = "Stage selected hunk" },
                        },
                        {
                            { "n", "v" },
                            "-",
                            ":Gitsigns reset_hunk<CR>",
                            { desc = "Reset selected hunk" },
                        },
                    },
                    file_history_panel = {
                        quitDiffViewKeymap,
                        {
                            "n",
                            "<cr>",
                            actions.select_entry,
                            { desc = "Open the diff for the selected entry" },
                        },
                    },
                },
            })
        end,
    },
    {
        "tpope/vim-fugitive",
        cmd = {
            "Git",
            "G",
        },

        keys = {
            {
                "<leader>g<C-p>",
                "<cmd>Git push -u <CR>",
                mode = "n",
                desc = "Git Push",
            },

            {
                "<leader>g<C-l>",
                "<cmd>Git pull --rebase --autostash <CR>",
                mode = "n",
                desc = "Git pull --rebase --autostash",
            },

            {
                "<leader>gd",
                "<cmd>Gvdiffsplit!<CR>",
                mode = "n",
                desc = "Show git diff for current file",
            },

            -- {
            --     "<leader>gb",
            --     "<CMD>Git blame<CR>",
            --     mode = "n",
            --     desc = "Git Blame",
            -- },

            {
                "<leader>gC",
                function()
                    local defaultName = "cgomes/"
                    vim.ui.input({
                        prompt = "Branch name: ",
                        default = defaultName,
                    }, function(newBranchName)
                        if
                            not newBranchName
                            or newBranchName == ""
                            or newBranchName == defaultName
                        then
                            vim.notify("Not creating a branch", "info")
                            return
                        end

                        vim.cmd("Git checkout -b " .. newBranchName)
                    end)
                end,
                mode = { "n", "v" },
                desc = "Git Create Branch",
            },

            {
                "<leader>gU",
                "<cmd>UndoLastCommit<CR>",
                mode = "n",
                desc = "Git Undo last commit",
            },
        },

        init = function()
            vim.api.nvim_create_user_command(
                "UndoLastCommit",
                "Git reset --soft HEAD~",
                {}
            )

            -- Disabling to use Diffview as default
            -- local fugitiveWinId = nil

            -- vim.keymap.set("n", "<leader>gs", function()
            --     vim.cmd("Git")
            --     fugitiveWinId = vim.api.nvim_get_current_win()
            --     vim.cmd("wincmd o ")
            --     vim.cmd("vnew")
            --     vim.cmd("wincmd 1w")
            --     vim.api.nvim_win_set_width(fugitiveWinId, 50)
            --     vim.cmd("norm 0)")
            -- end, { desc = "Show git status", silent = true })

            -- vim.api.nvim_create_autocmd("FileType", {
            --     desc = "Fugitive overrides",
            --     pattern = { "fugitive" },
            --     group = vim.api.nvim_create_augroup(
            --         "UserFugitive",
            --         { clear = true }
            --     ),
            --     callback = function(ev)
            --         vim.api.nvim_buf_set_keymap(
            --             ev.buf,
            --             "n",
            --             "cc",
            --             ":<C-U> wincmd o<CR> :vertical Git commit<CR>",
            --             {}
            --         )
            --     end,
            -- })

            -- local group = vim.api.nvim_create_augroup(
            --     "UserFugitiveOverrides",
            --     { clear = true }
            -- )

            -- vim.api.nvim_create_autocmd("BufEnter", {
            --     pattern = "COMMIT_EDITMSG",
            --     callback = function()
            --         vim.defer_fn(function()
            --             if fugitiveWinId then
            --                 vim.api.nvim_win_set_width(fugitiveWinId, 50)
            --             end
            --         end, 50)
            --     end,
            --     group = group,
            -- })

            -- vim.api.nvim_create_autocmd("BufLeave", {
            --     pattern = "COMMIT_EDITMSG",
            --     callback = function()
            --         vim.cmd("vnew")

            --         if fugitiveWinId then
            --             vim.defer_fn(function()
            --                 vim.api.nvim_set_current_win(fugitiveWinId)
            --                 vim.api.nvim_win_set_width(fugitiveWinId, 50)
            --             end, 50)
            --         end
            --     end,
            --     group = group,
            -- })
        end,
    },
}
