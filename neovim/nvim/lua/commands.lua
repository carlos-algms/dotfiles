vim.api.nvim_create_user_command("Redir", function(ctx)
    local ouput = vim.api.nvim_exec(ctx.args, true)
    local lines = vim.split(ouput, "\n", { plain = true })
    vim.cmd("vnew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.opt_local.modified = false
end, { nargs = "+", complete = "command" })

vim.api.nvim_create_user_command("Float", function(ctx)
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

    -- Create the floating window
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

vim.api.nvim_create_user_command("CopyRelativePath", function()
    local path = vim.fn.expand("%:.")
    vim.fn.setreg("+", path)
    vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

vim.api.nvim_create_user_command("CopyFullPath", function()
    local path = vim.fn.expand("%:p")
    vim.fn.setreg("+", path)
    vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})
