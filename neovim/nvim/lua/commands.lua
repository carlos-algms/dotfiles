local createUserCommand = vim.api.nvim_create_user_command

createUserCommand("Redir", function(ctx)
    local ouput = vim.api.nvim_exec(ctx.args, true)
    local lines = vim.split(ouput, "\n", { plain = true })
    vim.cmd("vnew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.opt_local.modified = false
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
end, {})

createUserCommand("CopyFullPath", function()
    local path = vim.fn.expand("%:p")
    vim.fn.setreg("+", path)
    vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

vim.keymap.set({ "n" }, "<leader>yr", "<cmd>CopyRelativePath<CR>", {
    desc = "Copy relative path",
    silent = true,
})

vim.keymap.set({ "n" }, "<leader>yF", "<cmd>CopyFullPath<CR>", {
    desc = "Copy full path",
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
    if os_name == "Darwin" then
        vim.fn.jobstart({ "open", "-R", filepath })
    elseif os_name == "Windows" or os_name == "Windows_NT" then
        vim.fn.jobstart({ "explorer", "/select," .. filepath:gsub("/", "\\") })
    elseif os_name == "Linux" then
        -- Try common Linux file explorers
        vim.fn.jobstart({ "xdg-open", vim.fn.fnamemodify(filepath, ":h") })
    else
        vim.notify("Unsupported OS: " .. os_name, vim.log.levels.ERROR)
    end
end, {
    desc = "Open the current file's directory in the file explorer",
})
