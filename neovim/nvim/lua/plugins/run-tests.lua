local P = {}

local M = {
    {
        "nvim-neotest/neotest",
        -- event = "VeryLazy",
        enabled = vim.g.has_node and not vim.g.is_ssh,
        -- event = "LspAttach",

        -- Disabled to only load when keybinding is used
        -- ft = {
        --     "javascript",
        --     "typescript",
        --     "javascriptreact",
        --     "typescriptreact",
        -- },

        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-neotest/nvim-nio",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-neotest/neotest-jest",
            "marilari88/neotest-vitest",
            "mfussenegger/nvim-dap",
        },

        keys = {
            {
                "<leader>Td",
                function()
                    require("neotest").run.run({
                        suite = false,
                        strategy = "dap",
                    })
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
                "<leader>TT", -- this might need to find the root of the project
                function()
                    require("neotest").run.run(vim.fn.getcwd())
                end,
                desc = "Run All Test Files",
            },
            {
                "<leader>Tn",
                function()
                    require("neotest").run.run({
                        suite = false,
                    })
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
                "<leader>Tw",
                function()
                    require("neotest").watch.toggle({
                        suite = false,
                    })
                end,
                desc = "Run test in watch mode",
            },
            {
                "<leader>TW",
                function()
                    require("neotest").watch.toggle({
                        suite = true,
                    })
                end,
                desc = "Run test in watch mode",
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

            ---@diagnostic disable-next-line: missing-fields
            neotest.setup({
                status = {
                    virtual_text = false,
                    enabled = true,
                    signs = true,
                },
                output = {
                    open_on_run = true,
                    enabled = true,
                },
                discovery = {
                    enabled = false,
                    concurrent = 0,
                },
                adapters = {
                    -- require("neotest-vitest"),
                    P.getJestAdapter(),
                },
            })

            vim.cmd([[
                hi! NeotestPassed guibg=#313335
                hi! NeotestFailed guibg=#313335
                hi! NeotestRunning guibg=#313335
                hi! NeotestSkipped guibg=#313335
            ]])
        end,
    },
}

function P.getJestAdapter()
    --- @param testFilePath string
    --- @return string
    local function getJestCommand(testFilePath)
        -- hack to enter watch mode and still find the jest config in a mono repo
        if testFilePath == vim.fn.getcwd() then
            testFilePath = vim.fn.expand("%:p")
        end

        local file = vim.fn.fnamemodify(testFilePath, ":p")
        local cmd = nil

        -- TODO: try to use find()
        --         local projects_dir = vim.fs.find("projects", {
        --              upwards = true,
        --              stop = vim.loop.os_homedir()
        --         })
        for p in vim.fs.parents(vim.fs.normalize(file) .. "/") do
            local path = p .. "/package.json"
            if vim.fn.filereadable(path) == 1 then
                local f = assert(io.open(path, "r"))
                local content = f:read("*a")
                f:close()
                local package = vim.json.decode(content)

                if package.scripts then
                    if package.scripts["test:unit"] then
                        cmd = "pnpm run --silent test:unit"
                        break
                    elseif package.scripts.test then
                        cmd = "pnpm run --silent test"
                        break
                    end
                end
            end
        end

        if not cmd then
            local neoTestJestUtils = require("neotest-jest.jest-util")
            cmd = neoTestJestUtils.getJestCommand(file)
        end

        -- vim.notify("jest cmd: " .. cmd)

        return cmd
    end

    --- @param testFilePath string
    local function getJestCwd(testFilePath)
        -- hack to enter watch mode and still find the jest config in a mono repo
        if testFilePath == vim.fn.getcwd() then
            testFilePath = vim.fn.expand("%:p")
        end

        local file = vim.fn.fnamemodify(testFilePath, ":p")

        for p in vim.fs.parents(vim.fs.normalize(file) .. "/") do
            local base = p .. "/jest.config"
            if vim.fn.filereadable(base .. ".js") == 1 then
                return p
            end
            if vim.fn.filereadable(base .. ".ts") == 1 then
                return p
            end
        end

        vim.notify("Could not find jest config file: " .. file)
        return vim.fn.getcwd()
    end

    return require("neotest-jest")({
        jest_test_discovery = true,
        jestCommand = getJestCommand,
        cwd = getJestCwd,
        env = {
            NODE_ENV = "test",
            DEBUG_PRINT_LIMIT = "1000000",
        },
    })
end

return M
