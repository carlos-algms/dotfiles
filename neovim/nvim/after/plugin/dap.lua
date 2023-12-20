local dap = require("dap")
local dapUtils = require("dap.utils")

vim.keymap.set("n", "<leader>db", "<cmd> DapToggleBreakpoint <CR>")
vim.keymap.set("n", "<leader>dr", "<cmd> DapContinue <CR>")
vim.keymap.set("n", "<leader>da", function()
    dap.continue({ before = get_args })
end)

-- # Sign
vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "🉑", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "ℹ️", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "➡️", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "⚪️", texthl = "", linehl = "", numhl = "" })

dap.adapters["pwa-node"] = {
    type = "server",
    host = "127.0.0.1",
    port = 8123,
    executable = {
        command = "js-debug-adapter",
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
            runtimeExecutable = "node",
            runtimeArgs = { "--inspect-brk=8123", "ts-node/register", "-r", "tsconfig-paths/register" },
            sourceMaps = true,
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

local dapui = require("dapui")
dapui.setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
end

dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
end

dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
end

require("nvim-dap-virtual-text").setup()
