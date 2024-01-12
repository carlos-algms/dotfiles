return {
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap" },
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
        dependencies = { "mfussenegger/nvim-dap" },
        config = function()
            require("nvim-dap-virtual-text").setup()
        end,
    },
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            {
                "nvim-telescope/telescope-dap.nvim",
                dependencies = {
                    "nvim-telescope/telescope.nvim",
                },
                config = function()
                    require("telescope").load_extension("dap")
                end,
            },
        },
        config = function()
            local dap = require("dap")
            local dapUtils = require("dap.utils")

            vim.keymap.set(
                "n",
                "<leader>db",
                "<cmd> DapToggleBreakpoint <CR>",
                { desc = "Toggle [D]ebugger [b]reakpoint" }
            )
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
            end)

            -- # Sign
            vim.fn.sign_define(
                "DapBreakpoint",
                { text = "🔴", texthl = "", linehl = "", numhl = "" }
            )
            vim.fn.sign_define(
                "DapBreakpointCondition",
                { text = "🉑", texthl = "", linehl = "", numhl = "" }
            )
            vim.fn.sign_define(
                "DapLogPoint",
                { text = "ℹ️", texthl = "", linehl = "", numhl = "" }
            )
            vim.fn.sign_define(
                "DapStopped",
                { text = "➡️", texthl = "", linehl = "", numhl = "" }
            )
            vim.fn.sign_define(
                "DapBreakpointRejected",
                { text = "⚪️", texthl = "", linehl = "", numhl = "" }
            )

            dap.adapters["pwa-node"] = {
                type = "server",
                host = "localhost",
                port = "${port}",
                executable = {
                    command = "js-debug-adapter",
                    args = { "${port}" },
                },
            }

            for _, language in ipairs({ "typescript", "javascript" }) do
                dap.configurations[language] = {
                    {
                        type = "pwa-node",
                        request = "launch",
                        name = "Launch file",
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
                        name = "Attach",
                        processId = dapUtils.pick_process,
                        cwd = vim.fn.getcwd(),
                        sourceMaps = true,
                    },
                }
            end

            dapui.setup()

            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end

            -- I don't want it to auto-close, as I want to check the output
            -- dap.listeners.before.event_terminated["dapui_config"] = function()
            --     -- dapui.close()
            -- end

            -- dap.listeners.before.event_exited["dapui_config"] = function()
            --     -- dapui.close()
            -- end

            require("nvim-dap-virtual-text").setup()
        end,
    },
}
