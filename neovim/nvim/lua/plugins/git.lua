return {
    {
        "pwntester/octo.nvim",
        -- dir = "/Users/carlos/projects/octo.nvim",
        -- TODO: Enable it only locally, not for SSH sessions
        enabled = true,
        event = "VeryLazy",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "nvim-tree/nvim-web-devicons",
        },
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
        config = function()
            local gitsigns = require("gitsigns")

            gitsigns.setup({
                on_attach = function(bufnr)
                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    map("n", "]c", function()
                        if vim.wo.diff then
                            vim.cmd.normal({ "]c", bang = true })
                        else
                            gitsigns.nav_hunk("next")
                        end
                    end, {
                        desc = "next change hunk",
                    })

                    map("n", "[c", function()
                        if vim.wo.diff then
                            vim.cmd.normal({ "[c", bang = true })
                        else
                            gitsigns.nav_hunk("prev")
                        end
                    end, {
                        desc = "prev change hunk",
                    })

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
        event = "VeryLazy",
        config = function()
            local actions = require("diffview.actions")

            vim.api.nvim_create_user_command(
                "CompareToMaster",
                "DiffviewOpen origin/HEAD...HEAD --imply-local",
                { desc = "Compare current branch to master" }
            )

            vim.keymap.set(
                { "n" },
                "<leader>gcm",
                "<cmd>CompareToMaster<CR>",
                { silent = true, desc = "[C]ompare current branch to [m]aster" }
            )

            vim.keymap.set(
                "n",
                "<leader>gs",
                "<cmd>DiffviewOpen<cr>",
                { desc = "Git status DiffView", silent = true }
            )

            local quitDiffViewKeymap = {
                "n",
                "gq",
                "<cmd>tabclose<cr>",
                { desc = "Close the Diffview" },
            }

            local commitKeyMap = {
                "n",
                "cc",
                "<cmd>tab G commit<cr>",
                { desc = "Commit staged files" },
            }

            local commitNoVerifyKeyMap = {
                "n",
                "cC",
                "<cmd>tab G commit --no-verify<cr>",
                { desc = "Commit staged files with --no-verify" },
            }

            local nextItemKeymap = {
                "n",
                "]q", -- TODO: do the same as select entry to focus on the first hunk
                actions.select_next_entry,
                { desc = "Open the diff for the next file" },
            }

            local prevItemKeymap = {
                "n",
                "[q",
                actions.select_prev_entry,
                { desc = "Open the diff for the previous file" },
            }

            require("diffview").setup({
                -- enabled because it wasn't diffing generated files
                diff_binaries = true,
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
                        nextItemKeymap,
                        prevItemKeymap,

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
                        nextItemKeymap,
                        prevItemKeymap,

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
                        nextItemKeymap,
                        prevItemKeymap,
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
        event = "VeryLazy",
        dependencies = {
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            local telescopeBuiltin = require("telescope.builtin")

            vim.api.nvim_create_user_command(
                "UndoLastCommit",
                "Git reset HEAD~",
                {}
            )

            vim.keymap.set(
                "n",
                "<C-S-p>",
                "<cmd>Git push -u <CR>",
                { desc = "[G]it [P]ush" }
            )

            vim.keymap.set(
                "n",
                "<leader>gb",
                telescopeBuiltin.git_branches,
                { desc = "Show [g]it [b]ranches" }
            )

            vim.keymap.set(
                "n",
                "<leader>gl",
                telescopeBuiltin.git_status,
                { desc = "Show [g]it [s]tatus as a list" }
            )

            vim.keymap.set(
                "n",
                "<leader>gh",
                "<cmd>DiffviewFileHistory % <CR>",
                { desc = "Show [G]it [H]istory for the current file" }
            )

            vim.keymap.set(
                "n",
                "<leader>gB",
                ":Git blame<CR>",
                { desc = "[G]it [B]lame" }
            )

            vim.keymap.set(
                "n",
                "<leader>gd",
                ":Gvdiffsplit!<CR>",
                { desc = "Show [g]it [d]iff for current file" }
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
            -- end, { desc = "Show [g]it [s]tatus", silent = true })

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
    -- {
    --     "knsh14/vim-github-link",
    --     -- cmd = { "GetCommitLink" },
    --     init = function()
    --         vim.keymap.set(
    --             { "n", "v" },
    --             "<leader>gC",
    --             ":GetCommitLink<CR>",
    --             { desc = "Copy git remote URL to clipboard" }
    --         )
    --     end,
    -- },
    {
        "linrongbin16/gitlinker.nvim",
        event = "VeryLazy",
        config = function()
            require("gitlinker").setup({
                message = false,
            })

            vim.keymap.set(
                { "n", "v" },
                "<leader>gy",
                "<cmd>GitLink<CR>",
                { desc = "Copy git remote URL to clipboard" }
            )
        end,
    },
}
