--     doesn't work
--     "mxsdev/nvim-dap-vscode-js",

return {
    {
        "mfussenegger/nvim-dap",
        lazy = true,
        enabled = not vim.g.is_ssh,
        dependencies = {
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
                        desc = "Toggle [D]ebugger [U]i - Dap UI",
                    },
                },
                config = function()
                    local dapui = require("dapui")
                    local dap = require("dap")

                    dap.listeners.before.attach.dapui_config = function()
                        -- dapui.open()
                        dap.repl.open()
                    end

                    dap.listeners.before.launch.dapui_config = function()
                        -- dapui.open()
                        dap.repl.open()
                    end

                    -- I don't want it to auto-close, as I want to check the output
                    -- dap.listeners.before.event_terminated.dapui_config = function()
                    --     -- dapui.close()
                    -- end

                    -- dap.listeners.before.event_exited.dapui_config = function()
                    --     -- dapui.close()
                    -- end

                    ---@diagnostic disable-next-line: missing-fields
                    dapui.setup({
                        layouts = {
                            {
                                elements = {
                                    {
                                        id = "scopes",
                                        size = 0.25,
                                    },
                                    {
                                        id = "breakpoints",
                                        size = 0.25,
                                    },
                                    {
                                        id = "stacks",
                                        size = 0.25,
                                    },
                                    {
                                        id = "watches",
                                        size = 0.25,
                                    },
                                },
                                position = "left",
                                size = 40,
                            },
                            {
                                elements = {
                                    -- Disabled to use Dap's repl, I usually don't use the sidebar widgets
                                    -- {
                                    --     id = "repl",
                                    --     size = 1,
                                    -- },
                                    -- Disabled, as for JavaScript it doesn't show any messages
                                    -- {
                                    --     id = "console",
                                    --     size = 0.5,
                                    -- },
                                },
                                position = "bottom",
                                size = 10,
                            },
                        },
                    })
                end,
            },
            {
                "nvim-telescope/telescope-dap.nvim",
                dependencies = {
                    "nvim-telescope/telescope.nvim",
                },
                keys = {
                    {
                        "<leader>dl",
                        ":Telescope dap list_breakpoints<CR>",
                        desc = " List breakpoint",
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
            {
                "theHamsta/nvim-dap-virtual-text",
            },
        },
        keys = {
            {
                "<leader>dc",
                function()
                    require("dap").repl.toggle()
                end,
                mode = { "n", "v" },
                desc = "󰟶 [D]ebugger [h]over",
            },
            {
                "<leader>dh",
                function()
                    require("dap.ui.widgets").hover()
                end,
                mode = { "n", "v" },
                desc = "󰟶 [D]ebugger [h]over",
            },

            {
                "<leader>dp",
                function()
                    require("dap.ui.widgets").preview()
                end,
                mode = { "n", "v" },
                desc = " [D]ebugger [p]review",
            },

            {
                "<leader>df",
                function()
                    require("dap.ui.widgets").centered_float(
                        require("dap.ui.widgets").frames
                    )
                end,
                mode = { "n", "v" },
                desc = " [D]ebugger [f]rames",
            },

            {
                "<leader>ds",
                function()
                    require("dap.ui.widgets").centered_float(
                        require("dap.ui.widgets").scopes
                    )
                end,
                mode = { "n", "v" },
                desc = "󰋃 [D]ebugger [s]copes",
            },

            {
                "<leader>db",
                "<cmd>DapToggleBreakpoint<CR>",
                mode = "n",
                desc = " Toggle [D]ebugger [b]reakpoint",
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
                desc = " Toggle [D]ebugger [B]reakpoint condition",
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
                desc = "󰯑 Toggle [D]ebugger [L]og point",
            },

            {
                "<leader>dr",
                "<cmd> DapContinue <CR>",
                mode = "n",
                desc = " [D]ebugger [R]un / Continue",
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
                { default = true, link = "Visual" }
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

            require("nvim-dap-virtual-text").setup({
                clear_on_continue = true,
            })
        end,
    },
}
