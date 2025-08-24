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
                    P.getVitestAdapter(),
                    P.getJestAdapter(),
                },
                floating = {
                    border = "rounded",
                    max_height = 0.6,
                    max_width = 0.6,
                    options = {},
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

local function path_join(...)
    return table.concat(vim.iter({ ... }):flatten():totable(), "/")
end

local function path_exists(...)
    local path = path_join(...)
    local stat = vim.uv.fs_stat(path)
    return stat and stat.type or false
end

local function is_file(...)
    return path_exists(...) == "file"
end

-- Returns the package manager for the current project directory.
local function getPackageManager()
    local root = vim.fn.getcwd()

    if
        is_file(root, "pnpm-lock.yaml") or is_file(root, "pnpm-workspace.yaml")
    then
        return "pnpm"
    elseif is_file(root, "yarn.lock") then
        return "yarn"
    elseif is_file(root, "bun.lockb") then
        return "bun"
    end

    return "npm"
end

local function getPackageJsonRootForCurrentFile()
    return vim.fs.root(0, { "package.json", "node_modules" })
end

--- @param dir string
local function readCommandFromPackageJson(dir)
    local path = dir .. "/package.json"

    if not is_file(path) then
        return nil
    end

    local f = assert(io.open(path, "r"))
    local content = f:read("*a")
    f:close()

    local package = vim.json.decode(content)

    if not package.scripts then
        return nil
    end

    local packageManager = getPackageManager()

    local cmd = nil

    if package.scripts["test:unit"] then
        cmd = packageManager .. " run --silent test:unit"
    elseif package.scripts.test then
        cmd = packageManager .. " run --silent test"
    end

    if cmd and packageManager == "npm" then
        cmd = cmd .. " --"
    end

    return cmd
end

--- @param name string
local function get_executable(name)
    local root = getPackageJsonRootForCurrentFile()

    if root then
        local cmd = readCommandFromPackageJson(root)

        if cmd then
            return cmd
        end

        local binary = path_join(root, "node_modules", ".bin", name)

        if path_exists(binary) then
            return binary
        end
    end

    return name
end

function P.getVitestAdapter()
    ---@type neotest.VitestOptions
    local config = {
        env = {
            NODE_ENV = "test",
            DEBUG_PRINT_LIMIT = "1000000",
        },
    }
    config.vitestCommand = function()
        return get_executable("vitest")
    end

    config.cwd = function()
        return getPackageJsonRootForCurrentFile() or vim.fn.getcwd()
    end

    --- @return string|nil
    config.vitestConfigFile = function()
        local rootPath = config.cwd()

        if not rootPath then
            return nil
        end

        local possibleVitestConfigNames = {
            "vitest.config.mts",
            "vitest.config.ts",
            "vitest.config.js",
            "vitest.config.mjs",
            "vite.config.mts",
            "vite.config.ts",
            "vite.config.js",
            "vite.config.mjs",
        }

        for _, configName in ipairs(possibleVitestConfigNames) do
            local configPath = path_join(rootPath, configName)

            if path_exists(configPath) then
                return configPath
            end
        end

        return nil
    end

    return require("neotest-vitest")(config)
end

function P.getJestAdapter()
    --- @type neotest.JestOptions
    local config = {
        jest_test_discovery = true,
        jestCommand = function()
            return get_executable("jest")
        end,
        cwd = function()
            return getPackageJsonRootForCurrentFile() or vim.fn.getcwd()
        end,
        env = {
            NODE_ENV = "test",
            DEBUG_PRINT_LIMIT = "1000000",
        },
    }

    return require("neotest-jest")(config)
end

return M
