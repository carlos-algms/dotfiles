return {
    {
        "nvim-neotest/neotest",
        -- event = "VeryLazy",
        event = "LspAttach",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-neotest/neotest-jest",
        },
        enabled = true,
        keys = {
            {
                "<leader><leader>td",
                function()
                    require("neotest").run.run({ strategy = "dap" })
                end,
                desc = "Debug nearest Test",
            },
            {
                "<leader><leader>tt",
                function()
                    require("neotest").run.run(vim.fn.expand("%"))
                end,
                desc = "Run File",
            },
            {
                "<leader><leader>tT",
                function()
                    require("neotest").run.run(vim.loop.cwd())
                end,
                desc = "Run All Test Files",
            },
            {
                "<leader><leader>tr",
                function()
                    require("neotest").run.run()
                end,
                desc = "Run Nearest",
            },
            {
                "<leader><leader>tl",
                function()
                    require("neotest").run.run_last()
                end,
                desc = "Run Last",
            },
            {
                "<leader><leader>ts",
                function()
                    require("neotest").summary.toggle()
                end,
                desc = "Toggle Summary",
            },
            {
                "<leader><leader>to",
                function()
                    require("neotest").output.open({
                        enter = true,
                        auto_close = true,
                    })
                end,
                desc = "Show Output",
            },
            {
                "<leader><leader>tO",
                function()
                    require("neotest").output_panel.toggle()
                end,
                desc = "Toggle Output Panel",
            },
            {
                "<leader><leader>tS",
                function()
                    require("neotest").run.stop()
                end,
                desc = "Stop",
            },
        },
        config = function()
            local neotest = require("neotest")
            local neoTestJestUtils = require("neotest-jest.jest-util")

            ---@diagnostic disable-next-line: missing-fields
            neotest.setup({
                status = { virtual_text = true },
                output = { open_on_run = true },
                discovery = {
                    enabled = false,
                },
                adapters = {
                    require("neotest-jest")({
                        jest_test_discovery = true,
                        -- jestCommand = "pnpm exec jest ",
                        jestCommand = function(testFilePath)
                            local cmd = neoTestJestUtils.getJestCommand(
                                -- vim.fn.expand("%:p")
                                vim.fn.fnamemodify(testFilePath, ":p")
                            )

                            vim.notify("cmd: " .. cmd)

                            return cmd
                        end,
                        -- jestConfigFile = function()
                        --     local file = vim.fn.expand("%:p")

                        --     for p in vim.fs.parents(vim.fs.normalize(file) .. "/") do
                        --         local base = p .. "/jest.cnofig"
                        --         if vim.fn.filereadable(base .. ".js") == 1 then
                        --             return p .. "/jest.config.js"
                        --         end
                        --         if vim.fn.filereadable(base .. ".ts") == 1 then
                        --             return p .. "/jest.config.ts"
                        --         end
                        --     end

                        --     return nil
                        -- end,
                        -- env = { CI = true },
                        cwd = function(testFilePath)
                            local file = vim.fn.fnamemodify(testFilePath, ":p")

                            for p in
                                vim.fs.parents(vim.fs.normalize(file) .. "/")
                            do
                                local base = p .. "/jest.config"
                                if vim.fn.filereadable(base .. ".js") == 1 then
                                    return p
                                end
                                if vim.fn.filereadable(base .. ".ts") == 1 then
                                    return p
                                end
                            end
                            vim.notify(
                                "Could not find jest config file: " .. file
                            )
                            return vim.fn.getcwd()
                        end,
                    }),
                },
            })

            -- vim.keymap.set(
            --     "n",
            --     "<leader><leader>tw",
            --     "<cmd>lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<cr>",
            --     { desc = "Run [t]est [w]atch mode" }
            -- )
        end,
    },
    {
        "David-Kunz/jester",
        enabled = false,
        config = function()
            require("jester").setup({
                cmd = "pnpm exec jest -t '$result' $file",
                path_to_jest_run = "pnpm exec jest ", -- used to run tests
                path_to_jest_debug = 'NODE_OPTIONS="--inspect-brk" pnpm exec jest ', -- used for debugging
                terminal_cmd = ":vsplit | terminal", -- used to spawn a terminal for running tests, for debugging refer to nvim-dap's config
                dap = { -- debug adapter configuration
                    type = "pwa-node",
                    request = "launch",
                    cwd = vim.fn.getcwd,
                    runtimeArgs = {
                        "--inspect-brk",
                        "$path_to_jest",
                        "--no-coverage",
                        "-t",
                        "$result",
                        "--",
                        "$file",
                    },
                    args = { "--no-cache" },
                    sourceMaps = false,
                    protocol = "inspector",
                    skipFiles = { "<node_internals>/**/*.js" },
                    console = "integratedTerminal",
                    port = 9229,
                    disableOptimisticBPs = true,
                },
            })
        end,
    },
}
