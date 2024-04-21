return {
    {
        "rcarriga/nvim-dap-ui",
        lazy = true,
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-neotest/nvim-nio",
        },
        config = function()
            local dapui = require("dapui")
            local dap = require("dap")
            local widgets = require("dap.ui.widgets")

            vim.keymap.set("n", "<leader>du", function()
                dapui.toggle()
            end, { desc = "Toggle [D]ebugger [U]i - Dap UI" })

            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end

            vim.keymap.set({ "n", "v" }, "<Leader>dh", function()
                widgets.hover()
            end, { desc = "Show [D]ebugger [H]over" })

            -- I don't want it to auto-close, as I want to check the output
            -- dap.listeners.before.event_terminated["dapui_config"] = function()
            --     -- dapui.close()
            -- end

            -- dap.listeners.before.event_exited["dapui_config"] = function()
            --     -- dapui.close()
            -- end

            dapui.setup()
        end,
    },
    {
        "theHamsta/nvim-dap-virtual-text",
        lazy = true,
        dependencies = { "mfussenegger/nvim-dap" },
        config = function()
            require("nvim-dap-virtual-text").setup({})
        end,
    },
    -- Disabled because it's not working
    -- {
    --     "mxsdev/nvim-dap-vscode-js",
    --     dependencies = { "mfussenegger/nvim-dap" },
    --     config = function()
    --         require("dap-vscode-js").setup({
    --             -- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
    --             -- debugger_path = "(runtimedir)/site/pack/packer/opt/vscode-js-debug", -- Path to vscode-js-debug installation.
    --             debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
    --             adapters = {
    --                 "pwa-node",
    --                 "pwa-chrome",
    --                 "pwa-msedge",
    --                 "node-terminal",
    --                 "pwa-extensionHost",
    --             }, -- which adapters to register in nvim-dap
    --             -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
    --             -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
    --             -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
    --         })
    --     end,
    -- },
    {
        "mfussenegger/nvim-dap",
        lazy = true,
        dependencies = {
            {
                "nvim-telescope/telescope-dap.nvim",
                dependencies = {
                    "nvim-telescope/telescope.nvim",
                },
                keys = {
                    {
                        "<leader>dl",
                        ":Telescope dap list_breakpoints<CR>",
                        desc = "List breakpoint",
                    },
                },
                config = function()
                    require("telescope").load_extension("dap")
                end,
            },
            {
                "LiadOz/nvim-dap-repl-highlights",
                -- dependencies = { "mfussenegger/nvim-dap" },
                config = function()
                    require("nvim-dap-repl-highlights").setup()
                end,
            },
        },
        config = function()
            local dap = require("dap")
            local dapUtils = require("dap.utils")

            -- Highlight the line where the debugger is stopped
            vim.api.nvim_set_hl(
                0,
                "DapStoppedLine",
                { default = true, link = "Visual" }
            )

            vim.keymap.set(
                "n",
                "<leader>db",
                "<cmd> DapToggleBreakpoint <CR>",
                { desc = "Toggle [D]ebugger [b]reakpoint" }
            )

            vim.keymap.set("n", "<leader>dB", function()
                dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
            end, {
                desc = "Toggle [D]ebugger [b]reakpoint condition",
            })

            vim.keymap.set(
                "n",
                "<f9>",
                "<cmd> DapToggleBreakpoint <CR>",
                { desc = "Toggle Debugger breakpoint" }
            )

            vim.keymap.set(
                "n",
                "<leader>dr",
                "<cmd> DapContinue <CR>",
                { desc = " [D]ebugger [R]un / Continue" }
            )

            vim.keymap.set(
                "n",
                "<leader>dt",
                "<cmd> DapTerminate <CR>",
                { desc = " Debugger terminate" }
            )

            vim.keymap.set(
                "n",
                "<s-f5>",
                "<cmd> DapTerminate <CR>",
                { desc = " Debugger terminate" }
            )

            vim.keymap.set(
                "n",
                "<f5>",
                "<cmd> DapContinue <CR>",
                { desc = " Debugger Run / Continue" }
            )

            vim.keymap.set(
                "n",
                "<f10>",
                "<cmd> DapStepOver <CR>",
                { desc = " Debugger Step Over" }
            )

            vim.keymap.set(
                "n",
                "<f11>",
                "<cmd> DapStepInto <CR>",
                { desc = " Debugger Step Into" }
            )

            vim.keymap.set(
                "n",
                "<s-f11>",
                "<cmd> DapStepOut <CR>",
                { desc = " Debugger Step Out" }
            )

            vim.keymap.set("n", "<leader>da", function()
                dap.continue({ before = get_args })
            end, { desc = " Debugger Run / Continue with args" })

            -- http://www.lazyvim.org/extras/dap/core#nvim-dap
            -- # Sign
            local dapSigns =
                { -- TODO: change highlight for Diagnostic** to have background color
                    Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
                    Breakpoint = " ",
                    BreakpointCondition = " ",
                    BreakpointRejected = { " ", "DiagnosticError" },
                    LogPoint = "󰯑 ",
                }

            for name, sign in pairs(dapSigns) do
                sign = type(sign) == "table" and sign or { sign }
                vim.fn.sign_define("Dap" .. name, {
                    text = sign[1],
                    texthl = sign[2] or "DiagnosticInfo",
                    linehl = sign[3],
                    numhl = sign[3],
                })
            end

            -- vim.fn.sign_define(
            --     "DapBreakpoint",
            --     { text = "🔴", texthl = "", linehl = "", numhl = "" }
            -- )

            -- vim.fn.sign_define(
            --     "DapBreakpointCondition",
            --     { text = "🉑", texthl = "", linehl = "", numhl = "" }
            -- )

            -- vim.fn.sign_define(
            --     "DapLogPoint",
            --     { text = "ℹ️", texthl = "", linehl = "", numhl = "" }
            -- )

            -- vim.fn.sign_define(
            --     "DapStopped",
            --     { text = "➡️", texthl = "", linehl = "", numhl = "" }
            -- )

            -- vim.fn.sign_define(
            --     "DapBreakpointRejected",
            --     { text = "⚪️", texthl = "", linehl = "", numhl = "" }
            -- )

            dap.adapters["pwa-node"] = {
                type = "server",
                host = "localhost",
                port = "${port}",
                executable = {
                    command = "js-debug-adapter",
                    args = { "${port}" },
                },
                skipFiles = {
                    "<node_internals>/**",
                    "**/node_modules/**/*",
                },
            }

            dap.adapters["pwa-chrome"] = {
                type = "server",
                host = "localhost",
                port = "${port}",
                executable = {
                    command = "js-debug-adapter",
                    args = { "${port}" },
                },
            }

            -- pwa-chrome isn't working fully
            -- https://stackoverflow.com/a/73427518/5930949
            dap.adapters["chrome"] = {
                type = "executable",
                command = "chrome-debug-adapter",
                -- host = "localhost",
                -- port = "${port}",
                -- executable = {
                --     command = "chrome-debug-adapter",
                --     -- args = { "${port}" },
                -- },
            }

            for _, language in ipairs({
                "typescript",
                "typescriptreact",
                "javascript",
                "javascriptreact",
            }) do
                dap.configurations[language] = {
                    {
                        type = "pwa-node",
                        request = "launch",
                        name = "Launch file " .. language,
                        program = "${file}",
                        cwd = "${workspaceFolder}",
                        runtimeExecutable = "ts-node",
                        -- runtimeArgs = {},
                        sourceMaps = true,
                        protocol = "inspector",
                        skipFiles = { "<node_internals>/**", "node_modules/**" },
                        resolveSourceMapLocations = {
                            "${workspaceFolder}/**",
                            "!**/node_modules/**",
                        },
                    },

                    {
                        type = "pwa-node",
                        request = "attach",
                        name = "Attach to Process " .. language,
                        processId = dapUtils.pick_process,
                        cwd = "${workspaceFolder}",
                        sourceMaps = true,
                    },

                    {
                        type = "pwa-chrome",
                        name = "Debug in Chrome",
                        request = "launch",
                        -- only the 3 first properties are required and need to be strings
                        -- the rest are optional and can be numbers, strings, or functions
                        -- see :h dap-configuration
                        url = function()
                            return coroutine.create(function(dap_run_co)
                                vim.ui.input({
                                    prompt = "Enter URL: ",
                                    default = "http://localhost:3000",
                                }, function(url)
                                    if url == nil or url == "" then
                                        url = "http://localhost:3000"
                                    end

                                    coroutine.resume(dap_run_co, url)
                                end)
                            end)
                        end,
                        -- TODO: find the nearest package.json and use it as cwd, or use current cwd
                        webRoot = "${workspaceFolder}",
                        -- sourceMapPathOverrides = {
                        --     ["webpack:///src/*"] = "${webRoot}/*",
                        --     ["/app/src/*"] = "${webRoot}/*",
                        -- },
                        userDataDir = false,
                        sourceMaps = true,
                    },
                }
            end

            dap.adapters["php"] = {
                type = "executable",
                command = "php-debug-adapter",
            }

            dap.configurations.php = {
                {
                    type = "php",
                    request = "launch",
                    name = "PHP: Listen for Xdebug",
                    port = 9003,
                    stopOnEntry = false,
                    pathMappings = {
                        -- TODO: this should be per project or dynamic
                        ["/var/www/html"] = "${workspaceFolder}/server",
                        ["/home/abc/public_html"] = "${workspaceFolder}/server",
                        ["/home/abc/workspace/server"] = "${workspaceFolder}/server",
                        ["/home/abc/deploys/1"] = "${workspaceFolder}/server",
                    },
                },
            }

            -- TODO: add adapter for python
        end,
    },
}
