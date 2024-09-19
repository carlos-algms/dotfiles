return {
    {
        "nvim-neotest/neotest",
        -- event = "VeryLazy",
        enabled = vim.g.has_node and not vim.g.is_ssh,
        -- event = "LspAttach",

        -- Remember to add more file types if I start testing other languages
        ft = {
            "javascript",
            "typescript",
            "javascriptreact",
            "typescriptreact",
        },

        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-neotest/nvim-nio",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-neotest/neotest-jest",
        },
        keys = {
            {
                "<leader>Td",
                function()
                    require("neotest").run.run({ strategy = "dap" })
                end,
                desc = "Debug nearest Test",
            },
            {
                "<leader>Tf",
                function()
                    require("neotest").run.run(vim.fn.expand("%"))
                end,
                desc = "Run File",
            },
            {
                "<leader>TT",
                function()
                    require("neotest").run.run(vim.loop.cwd())
                end,
                desc = "Run All Test Files",
            },
            {
                "<leader>Tn",
                function()
                    require("neotest").run.run()
                end,
                desc = "Run Nearest",
            },
            {
                "<leader>Tl",
                function()
                    require("neotest").run.run_last()
                end,
                desc = "Run Last",
            },
            {
                "<leader>Ts",
                function()
                    require("neotest").summary.toggle()
                end,
                desc = "Toggle Summary",
            },
            {
                "<leader>To",
                function()
                    require("neotest").output.open({
                        enter = true,
                        auto_close = true,
                    })
                end,
                desc = "Show Output",
            },
            {
                "<leader>TO",
                function()
                    require("neotest").output_panel.toggle()
                end,
                desc = "Toggle Output Panel",
            },
            {
                "<leader>TS",
                function()
                    require("neotest").run.stop()
                end,
                desc = "Stop",
            },
            {
                "]t",
                function()
                    require("neotest").jump.next()
                end,
                desc = "Next test",
            },
            {
                "[t",
                function()
                    require("neotest").jump.prev()
                end,
                desc = "Previous test",
            },
            {
                "]T",
                function()
                    require("neotest").jump.next({ status = "failed" })
                end,
                desc = "Next failed test",
            },
            {
                "[T",
                function()
                    require("neotest").jump.prev({ status = "failed" })
                end,
                desc = "Previous failed test",
            },
        },
        config = function()
            local neotest = require("neotest")
            local neoTestJestUtils = require("neotest-jest.jest-util")

            ---@diagnostic disable-next-line: missing-fields
            neotest.setup({
                status = { virtual_text = false },
                output = { open_on_run = true },
                discovery = {
                    enabled = false,
                },
                adapters = {
                    require("neotest-jest")({
                        jest_test_discovery = false,
                        jestCommand = function(testFilePath)
                            local file = vim.fn.fnamemodify(testFilePath, ":p")

                            -- TODO: try to use find()
                            --         local projects_dir = vim.fs.find("projects", {
                            --              upwards = true,
                            --              stop = vim.loop.os_homedir()
                            --         })
                            for p in
                                vim.fs.parents(vim.fs.normalize(file) .. "/")
                            do
                                local path = p .. "/package.json"
                                if vim.fn.filereadable(path) == 1 then
                                    local f = assert(io.open(path, "r"))
                                    local content = f:read("*a")
                                    f:close()
                                    local package = vim.json.decode(content)
                                    local cmd = nil

                                    if package.scripts then
                                        if package.scripts["test:unit"] then
                                            cmd = "pnpm run --silent test:unit"
                                        elseif package.scripts.test then
                                            cmd = "pnpm run --silent test"
                                        end
                                    end

                                    if cmd then
                                        vim.notify(
                                            "jest cmd from package.json: "
                                                .. cmd
                                        )
                                        return cmd
                                    end

                                    break
                                end
                            end

                            local cmd = neoTestJestUtils.getJestCommand(file)

                            vim.notify("jest cmd: " .. cmd)

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

            vim.cmd([[
                hi! NeotestPassed guibg=#313335
                hi! NeotestFailed guibg=#313335
                hi! NeotestRunning guibg=#313335
                hi! NeotestSkipped guibg=#313335
            ]])

            -- vim.keymap.set(
            --     "n",
            --     "<leader>Tw",
            --     "<cmd>lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<cr>",
            --     { desc = "Run [t]est [w]atch mode" }
            -- )
        end,
    },
    -- {
    --     "David-Kunz/jester",
    --     enabled = false,
    --     config = function()
    --         require("jester").setup({
    --             cmd = "pnpm exec jest -t '$result' $file",
    --             path_to_jest_run = "pnpm exec jest ", -- used to run tests
    --             path_to_jest_debug = 'NODE_OPTIONS="--inspect-brk" pnpm exec jest ', -- used for debugging
    --             terminal_cmd = ":vsplit | terminal", -- used to spawn a terminal for running tests, for debugging refer to nvim-dap's config
    --             dap = { -- debug adapter configuration
    --                 type = "pwa-node",
    --                 request = "launch",
    --                 cwd = vim.fn.getcwd,
    --                 runtimeArgs = {
    --                     "--inspect-brk",
    --                     "$path_to_jest",
    --                     "--no-coverage",
    --                     "-t",
    --                     "$result",
    --                     "--",
    --                     "$file",
    --                 },
    --                 args = { "--no-cache" },
    --                 sourceMaps = false,
    --                 protocol = "inspector",
    --                 skipFiles = { "<node_internals>/**/*.js" },
    --                 console = "integratedTerminal",
    --                 port = 9229,
    --                 disableOptimisticBPs = true,
    --             },
    --         })
    --     end,
    -- },
}
