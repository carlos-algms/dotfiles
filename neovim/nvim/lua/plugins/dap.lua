return {
    {
        "mfussenegger/nvim-dap",
        lazy = true,
        enabled = not vim.g.is_ssh,
        dependencies = {
            {
                {
                    "rcarriga/nvim-dap-ui",
                    dependencies = {
                        "nvim-neotest/nvim-nio",
                    },
                    keys = {
                        {
                            "<leader>du",
                            function()
                                require("dapui").toggle()
                            end,
                            desc = "Toggle Debugger Ui - Dap UI",
                        },
                    },
                    config = function()
                        local dapUi = require("dapui")
                        local dap = require("dap")

                        dap.listeners.before.attach.dapui_config = function()
                            -- Leaving disabled as I mostly don't use it
                            -- dapui.open()
                            -- Dap Repl resizes to 50% every time anything changes, disabling as it is inconvenient, use <leader>dc to open it
                            -- dap.repl.open()
                        end

                        dap.listeners.before.launch.dapui_config = function()
                            -- dapui.open()
                            -- dap.repl.open()
                        end

                        -- I don't want it to auto-close, as I want to check the output
                        -- dap.listeners.before.event_terminated.dapui_config = function()
                        --     -- dapui.close()
                        -- end

                        -- dap.listeners.before.event_exited.dapui_config = function()
                        --     -- dapui.close()
                        -- end

                        ---@diagnostic disable-next-line: missing-fields
                        dapUi.setup({
                            layouts = {
                                {
                                    elements = {
                                        {
                                            id = "scopes",
                                            size = 0.35,
                                        },
                                        {
                                            id = "breakpoints",
                                            size = 0.25,
                                        },
                                        {
                                            id = "stacks",
                                            size = 0.35,
                                        },
                                    },
                                    position = "left",
                                    size = 40,
                                },
                                {
                                    elements = {
                                        {
                                            id = "repl",
                                            size = 0.5,
                                        },
                                        -- {
                                        --     id = "watches",
                                        --     size = 0.24,
                                        -- },
                                        {
                                            id = "console",
                                            size = 0.5,
                                        },
                                    },
                                    position = "bottom",
                                    size = 10,
                                },
                            },
                        })
                    end,
                },
            },
            {
                "LiadOz/nvim-dap-repl-highlights",
                config = function()
                    require("nvim-dap-repl-highlights").setup()
                end,
            },
        },
        keys = {
            {
                "<leader>dl",
                function()
                    require("dap").list_breakpoints(false)
                    Snacks.picker.qflist()
                end,
                desc = " Debugger list breakpoints",
            },
            {
                "<leader>dc",
                function()
                    require("dap").repl.toggle()
                end,
                mode = { "n", "v" },
                desc = "󰟶 Debugger show Repl console",
            },
            {
                "<leader>dh",
                function()
                    require("dap.ui.widgets").hover()
                end,
                mode = { "n", "v" },
                desc = "󰟶 Debugger hover",
            },

            {
                "<leader>dp",
                function()
                    require("dap.ui.widgets").preview()
                end,
                mode = { "n", "v" },
                desc = " Debugger preview",
            },

            {
                "<leader>df",
                function()
                    require("dap.ui.widgets").centered_float(
                        require("dap.ui.widgets").frames
                    )
                end,
                mode = { "n", "v" },
                desc = " Debugger frames",
            },

            {
                "<leader>ds",
                function()
                    require("dap.ui.widgets").centered_float(
                        require("dap.ui.widgets").scopes
                    )
                end,
                mode = { "n", "v" },
                desc = "󰋃 Debugger scopes",
            },

            {
                "<leader>db",
                "<cmd>DapToggleBreakpoint<CR>",
                mode = "n",
                desc = " Toggle Debugger breakpoint",
            },

            {
                "<f9>",
                "<cmd>DapToggleBreakpoint<CR>",
                mode = "n",
                desc = " Toggle Debugger breakpoint",
            },

            {
                "<leader>dB",
                function()
                    vim.ui.input({
                        prompt = "Breakpoint condition: ",
                    }, function(condition)
                        require("dap").set_breakpoint(nil, condition)
                    end)
                end,
                mode = "n",
                desc = " Toggle Debugger Breakpoint condition",
            },

            {
                "<leader>dL",
                function()
                    vim.ui.input({
                        prompt = "Log point message: ",
                    }, function(message)
                        require("dap").set_breakpoint(nil, nil, message)
                    end)
                end,
                mode = "n",
                desc = "󰯑 Toggle Debugger Log point",
            },

            {
                "<leader>dr",
                "<cmd> DapContinue <CR>",
                mode = "n",
                desc = " Debugger Run / Continue",
            },

            {
                "<leader>dt",
                "<cmd> DapTerminate <CR>",
                mode = "n",
                desc = "󱎘 Debugger terminate",
            },

            {
                "<s-f5>",
                "<cmd> DapTerminate <CR>",
                mode = "n",
                desc = "󱎘 Debugger terminate",
            },

            {
                "<f5>",
                "<cmd> DapContinue <CR>",
                mode = "n",
                desc = "󰐊 Debugger Run / Continue",
            },

            {
                "<f10>",
                "<cmd> DapStepOver <CR>",
                mode = "n",
                desc = " Debugger Step Over",
            },

            {
                "<f11>",
                "<cmd> DapStepInto <CR>",
                mode = "n",
                desc = " Debugger Step Into",
            },

            {
                "<leader>di",
                "<cmd> DapStepInto <CR>",
                mode = "n",
                desc = " Debugger Step Into",
            },

            {
                "<s-f11>",
                "<cmd> DapStepOut <CR>",
                mode = "n",
                desc = " Debugger Step Out",
            },

            {
                "<leader>do",
                "<cmd> DapStepOut <CR>",
                mode = "n",
                desc = " Debugger Step Out",
            },

            {
                "<leader>da",
                function()
                    require("dap").continue({ before = get_args })
                end,
                mode = "n",
                desc = "󰐊 Debugger Run / Continue with args",
            },
        },
        config = function()
            local dap = require("dap")
            local dapUtils = require("dap.utils")

            -- Highlight the line where the debugger is stopped
            vim.api.nvim_set_hl(
                0,
                "DapStoppedLine",
                { default = true, link = "DiffChange" } -- using DiffChange so Visual select isn’t same color
            )

            -- http://www.lazyvim.org/extras/dap/core#nvim-dap
            -- # Sign
            local dapSigns =
                { -- TODO: change highlight for Diagnostic** to have background color
                    Stopped = {
                        "󰁕 ",
                        "DiagnosticSignWarn",
                        "DapStoppedLine",
                    },
                    Breakpoint = { " " },
                    BreakpointCondition = { " " },
                    BreakpointRejected = { " ", "DiagnosticSignError" },
                    LogPoint = { "󰯑 " },
                }

            for name, sign in pairs(dapSigns) do
                vim.fn.sign_define("Dap" .. name, {
                    text = sign[1],
                    texthl = sign[2] or "DiagnosticSignInfo",
                    linehl = sign[3],
                    numhl = sign[3],
                })
            end

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
                        runtimeExecutable = "tsx",
                        -- runtimeArgs = {},
                        sourceMaps = true,
                        protocol = "inspector",
                        skipFiles = {
                            "<node_internals>/**",
                            "node_modules/**",
                        },
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
                        -- Not using pwa-chrome as it doesn't work
                        type = "chrome",
                        name = "Debug in Chrome",
                        request = "launch",
                        -- only the 3 first properties are required and need to be strings
                        -- the rest are optional and can be numbers, strings, or functions
                        -- see :h dap-configuration
                        url = function()
                            return coroutine.create(function(dap_run_co)
                                vim.ui.input({
                                    prompt = "Enter URL: ",
                                    -- TODO: how to make it configurable per project?
                                    default = "http://localhost:3000",
                                }, function(url)
                                    if url == nil or url == "" then
                                        url = "http://localhost:3000"
                                    end

                                    coroutine.resume(dap_run_co, url)
                                end)
                            end)
                        end,
                        -- mainly to cover monorepos where the root is not the same as the workspace
                        cwd = function()
                            local rootDirs = vim.fs.find(function(name, path)
                                print(name, path)
                                return vim.fn.filereadable(
                                    path .. "/" .. name .. "/package.json"
                                ) == 1
                            end, {
                                upward = true,
                                type = "directory",
                                stop = vim.env.HOME,
                                path = vim.fn.expand("%:p:h"),
                            })

                            if #rootDirs == 0 then
                                vim.notify(
                                    "Couldn't find package.json in the current directory or any parent directory",
                                    vim.log.levels.ERROR
                                )

                                print(vim.inspect(rootDirs))
                                return "${workspaceFolder}"
                            end

                            vim.notify(
                                "Found package.json at "
                                    .. rootDirs[1]
                                    .. " using as cwd for Dap"
                            )

                            return rootDirs[1]
                        end,
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
                -- port = "${port}",
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
                        ["/home/abc/public_html"] = "${workspaceFolder}/wordpress",
                        -- ["/home/abc/public_html"] = "${workspaceFolder}/server",
                        ["/home/abc/workspace/server"] = "${workspaceFolder}/server",
                        ["/home/abc/deploys/1"] = "${workspaceFolder}/server",
                    },
                },
            }

            -- TODO: add adapter for python
        end,
    },
}
