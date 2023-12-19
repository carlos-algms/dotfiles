local dap = require("dap")
local dapUtils = require("dap.utils")

vim.keymap.set("n", "<leader>db", "<cmd> DapToggleBreakpoint <CR>")
vim.keymap.set("n", "<leader>dr", "<cmd> DapContinue <CR>")
vim.keymap.set("n", "<leader>da", function()
    dap.continue({ before = get_args })
end)

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
            runtimeExecutable = "ts-node",
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
