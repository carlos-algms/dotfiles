local createUserCommand = vim.api.nvim_create_user_command

createUserCommand("Redir", function(ctx)
    local ouput = vim.api.nvim_exec(ctx.args, true)
    local lines = vim.split(ouput, "\n", { plain = true })
    vim.cmd("vnew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.opt_local.modified = false
    vim.opt_local.buftype = "nofile"
end, { nargs = "+", complete = "command" })

createUserCommand("Float", function(ctx)
    local width = 130
    local height = 25

    -- Create the scratch buffer displayed in the floating window
    local buf = vim.api.nvim_create_buf(false, true)

    -- close the buffer with q
    vim.keymap.set({ "n", "v" }, "q", ":q<CR>", { buffer = buf })

    -- Set the buffer's contents to the output of the command
    local ouput = vim.api.nvim_exec(ctx.args, true)
    local lines = vim.split(ouput, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Get the current UI
    local uis = vim.api.nvim_list_uis()

    local ui = uis[0] or uis[1]

    --- Create the floating window
    --- @type vim.api.keyset.win_config
    local opts = {
        relative = "editor",
        width = width,
        height = height,
        col = (ui.width / 2) - (width / 2),
        row = (ui.height / 2) - (height / 2),
        anchor = "NW",
        style = "minimal",
        border = "rounded",
        title = ctx.args,
        title_pos = "left",
    }

    local win = vim.api.nvim_open_win(buf, true, opts)
end, { nargs = "+", complete = "command" })

createUserCommand("CopyRelativePath", function()
    local path = vim.fn.expand("%:.")
    vim.fn.setreg("+", path)
    vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {
    desc = "Copy relative path to the system clipboard",
})

createUserCommand("CopyAbsolutePath", function()
    local path = vim.fn.expand("%:p")
    vim.fn.setreg("+", path)
    vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {
    desc = "Copy absolute path to system clipboard",
})

vim.keymap.set({ "n" }, "<Leader>Yr", "<cmd>CopyRelativePath<CR>", {
    desc = "Copy relative path to system clipboard",
    silent = true,
})

vim.keymap.set({ "n" }, "<Leader>Ya", "<cmd>CopyAbsolutePath<CR>", {
    desc = "Copy absolute path to system clipboard",
    silent = true,
})

createUserCommand("CloseAllOtherBuffers", function()
    local current = vim.fn.bufnr()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= current then
            vim.api.nvim_buf_delete(buf, { force = false })
        end
    end
end, {})

createUserCommand("RevelInExplorer", function()
    local filepath = vim.fn.expand("%:p")
    if filepath == "" then
        vim.notify("No file in current buffer", vim.log.levels.ERROR)
        return
    end

    local os_name = vim.loop.os_uname().sysname
    local explorer_map = {
        Darwin = { "open", "-R", filepath },
        Windows = { "explorer", "/select," .. filepath:gsub("/", "\\") },
        ["Windows_NT"] = { "explorer", "/select," .. filepath:gsub("/", "\\") },
        Linux = { "xdg-open", vim.fn.fnamemodify(filepath, ":h") },
    }

    local command = explorer_map[os_name]
    if command then
        vim.fn.jobstart(command, {
            on_exit = function(_, exit_code)
                if exit_code ~= 0 then
                    vim.notify(
                        "Failed to open the explorer",
                        vim.log.levels.ERROR
                    )
                else
                    vim.notify(
                        "Explorer opened successfully",
                        vim.log.levels.INFO
                    )
                end
            end,
        })
    else
        vim.notify("Unsupported OS: " .. os_name, vim.log.levels.ERROR)
    end
end, {
    desc = "Open the current file's directory in the file explorer",
})
